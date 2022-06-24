//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// mach_msg_server_once.c
// Created by Patrick Gili on 6/15/22.
//

#include <stdlib.h>
#include <mach/mach.h>
#include <mach/boolean.h>
#include <mach/kern_return.h>
#include <mach/message.h>
#include <mach/mig_errors.h>
#include <mach/vm_statistics.h>
#include <TargetConditionals.h>

static inline boolean_t
mach_msg_server_is_recoverable_send_error(kern_return_t kr)
{
    switch (kr) {
    case MACH_SEND_INVALID_DEST:
    case MACH_SEND_TIMED_OUT:
    case MACH_SEND_INTERRUPTED:
        return TRUE;
    default:
        /*
         * Other errors mean that the message may have been partially destroyed
         * by the kernel, and these can't be recovered and may leak resources.
         */
        return FALSE;
    }
}

static kern_return_t
mach_msg_server_mig_return_code(mig_reply_error_t *reply)
{
    /*
     * If the message is complex, it is assumed that the reply was successful,
     * as the RetCode is where the count of out of line descriptors is.
     *
     * If not, we read RetCode.
     */
    if (reply->Head.msgh_bits & MACH_MSGH_BITS_COMPLEX) {
        return KERN_SUCCESS;
    }
    return reply->RetCode;
}

static void
mach_msg_server_consume_unsent_message(mach_msg_header_t *hdr)
{
    /* mach_msg_destroy doesn't handle the local port */
    mach_port_t port = hdr->msgh_local_port;
    if (MACH_PORT_VALID(port)) {
        switch (MACH_MSGH_BITS_LOCAL(hdr->msgh_bits)) {
        case MACH_MSG_TYPE_MOVE_SEND:
        case MACH_MSG_TYPE_MOVE_SEND_ONCE:
            /* destroy the send/send-once right */
            (void) mach_port_deallocate(mach_task_self_, port);
            hdr->msgh_local_port = MACH_PORT_NULL;
            break;
        }
    }
    mach_msg_destroy(hdr);
}

/*
 *    Routine:    mach_msg_server_once_with_timeout
 *    Purpose:
 *        A simple generic server function.  It allows more flexibility
 *        than mach_msg_server by processing only one message request
 *        and then returning to the user.  Note that more in the way
 *        of error codes are returned to the user; specifically, any
 *        failing error from mach_msg calls will be returned
 *        (though errors from the demux routine or the routine it
 *        calls will not be).
 */
mach_msg_return_t
mach_msg_server_once_with_timeout(boolean_t (*demux)(mach_msg_header_t *, mach_msg_header_t *),
                                  mach_msg_size_t max_size,
                                  mach_port_t rcv_name,
                                  mach_msg_options_t options,
                                  mach_msg_timeout_t timeout)
{
    mig_reply_error_t *bufRequest, *bufReply;
    mach_msg_size_t request_size;
    mach_msg_size_t request_alloc;
    mach_msg_size_t trailer_alloc;
    mach_msg_size_t reply_alloc;
    mach_msg_return_t mr;
    kern_return_t kr;
    mach_port_t self = mach_task_self_;
    voucher_mach_msg_state_t old_state = VOUCHER_MACH_MSG_STATE_UNCHANGED;

    options &= ~(MACH_SEND_MSG | MACH_RCV_MSG | MACH_RCV_VOUCHER);

    trailer_alloc = REQUESTED_TRAILER_SIZE(options);
    request_alloc = (mach_msg_size_t)round_page(max_size + trailer_alloc);

    request_size = (options & MACH_RCV_LARGE) ?
        request_alloc : max_size + trailer_alloc;

    reply_alloc = (mach_msg_size_t)round_page((options & MACH_SEND_TRAILER) ?
        (max_size + MAX_TRAILER_SIZE) :
        max_size);

    kr = vm_allocate(self,
        (vm_address_t *)&bufReply,
        reply_alloc,
        VM_MAKE_TAG(VM_MEMORY_MACH_MSG) | TRUE);
    if (kr != KERN_SUCCESS) {
        return kr;
    }

    for (;;) {
        mach_msg_size_t new_request_alloc;

        kr = vm_allocate(self,
            (vm_address_t *)&bufRequest,
            request_alloc,
            VM_MAKE_TAG(VM_MEMORY_MACH_MSG) | TRUE);
        if (kr != KERN_SUCCESS) {
            vm_deallocate(self,
                (vm_address_t)bufReply,
                reply_alloc);
            return kr;
        }

        mr = mach_msg(&bufRequest->Head, MACH_RCV_MSG | MACH_RCV_VOUCHER | options,
            0, request_size, rcv_name,
            timeout, MACH_PORT_NULL);

        if (mr == MACH_RCV_TIMED_OUT) {
            break;
        }
        
        if (!((mr == MACH_RCV_TOO_LARGE) && (options & MACH_RCV_LARGE))) {
            break;
        }
        
        new_request_alloc = (mach_msg_size_t)round_page(bufRequest->Head.msgh_size +
            trailer_alloc);
        vm_deallocate(self,
            (vm_address_t) bufRequest,
            request_alloc);
        request_size = request_alloc = new_request_alloc;
    }

    if (mr == MACH_MSG_SUCCESS) {
        /* we have a request message */

        old_state = voucher_mach_msg_adopt(&bufRequest->Head);

        (void) (*demux)(&bufRequest->Head, &bufReply->Head);

        switch (mach_msg_server_mig_return_code(bufReply)) {
        case KERN_SUCCESS:
            break;
        case MIG_NO_REPLY:
            bufReply->Head.msgh_remote_port = MACH_PORT_NULL;
            break;
        default:
            /*
             * destroy the request - but not the reply port
             * (MIG moved it into the bufReply).
             */
            bufRequest->Head.msgh_remote_port = MACH_PORT_NULL;
            mach_msg_destroy(&bufRequest->Head);
        }

        /*
         *    We don't want to block indefinitely because the client
         *    isn't receiving messages from the reply port.
         *    If we have a send-once right for the reply port, then
         *    this isn't a concern because the send won't block.
         *    If we have a send right, we need to use MACH_SEND_TIMEOUT.
         *    To avoid falling off the kernel's fast RPC path unnecessarily,
         *    we only supply MACH_SEND_TIMEOUT when absolutely necessary.
         */
        if (bufReply->Head.msgh_remote_port != MACH_PORT_NULL) {
            mr = mach_msg(&bufReply->Head,
                (MACH_MSGH_BITS_REMOTE(bufReply->Head.msgh_bits) ==
                MACH_MSG_TYPE_MOVE_SEND_ONCE) ?
                MACH_SEND_MSG | options :
                MACH_SEND_MSG | MACH_SEND_TIMEOUT | options,
                bufReply->Head.msgh_size, 0, MACH_PORT_NULL,
                MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);

            if (mach_msg_server_is_recoverable_send_error(mr)) {
                mach_msg_server_consume_unsent_message(&bufReply->Head);
                mr = MACH_MSG_SUCCESS;
            }
        }
    }

    voucher_mach_msg_revert(old_state);

    (void)vm_deallocate(self,
        (vm_address_t) bufRequest,
        request_alloc);
    (void)vm_deallocate(self,
        (vm_address_t) bufReply,
        reply_alloc);
    return mr;
}
