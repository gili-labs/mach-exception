//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// main.c
// Created by Patrick Gili on 4/12/22.
//

#import <Foundation/Foundation.h>
#import <mach/kern_return.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <pthread/pthread.h>
#include "mach_excServer.h"
#include "mach_exceptions.h"

// Determine whether a given exception context has been used by thread_swap_exception_ports
// to store an old set of masks.
//
// - Parameters:
//   - context: The context being tested.
//
// - Returns: A boolean-value indicating whether the given exception context has been used by
//   thread_swap_exception_ports to store an old set of masks.
bool is_exception_ports_swapped(ExceptionContext * context) {
    if (context->count != EXC_TYPES_COUNT) {
        return false;
    }
    
    for (int i = 0; i < EXC_TYPES_COUNT; i++) {
        if (context->masks[i] != 0) {
            return false;
        }
        
        if (context->ports[i] != 0) {
            return false;
        }
        
        if (context->behaviors[i] != 0) {
            return false;
        }
        
        if (context->flavors[i] != 0) {
            return false;
        }
    }
    
    return true;
}

typedef struct {
    exception_type_t exception;
    mach_exception_code_t code;
    mach_exception_subcode_t subcode;
    void * class;
    void (* handler)(void *, exception_type_t, mach_exception_code_t, mach_exception_subcode_t);
} exception_info_t;

static pthread_key_t exception_context_key;
static pthread_once_t exception_context_key_once = PTHREAD_ONCE_INIT;

static void make_exception_context_key() {
    pthread_key_create(&exception_context_key, NULL);
}

static void exc_handler(exception_info_t * info) {
    __uint64_t threadid;
    if (info->handler != NULL) {
        info->handler(info->class, info->exception, info->code, info->code);
    }
    free(info);
    pthread_exit(NULL);
}

kern_return_t catch_mach_exception_raise(mach_port_t exception_port,
                                         mach_port_t thread,
                                         mach_port_t task,
                                         exception_type_t exception,
                                         mach_exception_data_t code,
                                         mach_msg_type_number_t codeCnt) {
    fprintf(stderr, "catch_mach_exception_raise called\n");
    return KERN_NOT_SUPPORTED;
}

kern_return_t catch_mach_exception_raise_state(mach_port_t exception_port,
                                               exception_type_t exception,
                                               const mach_exception_data_t code,
                                               mach_msg_type_number_t codeCnt,
                                               int *flavor,
                                               const thread_state_t old_state,
                                               mach_msg_type_number_t old_stateCnt,
                                               thread_state_t new_state,
                                               mach_msg_type_number_t *new_stateCnt) {
    fprintf(stderr, "catch_mach_exception_raise_state called\n");
    return KERN_NOT_SUPPORTED;
}

#if defined (__arm__) || defined (__arm64__)
#define EXCEPTION_THREAD_STATE          ARM_THREAD_STATE64
#define EXCEPTION_THREAD_STATE_COUNT    ARM_THREAD_STATE64_COUNT
#elif defined (__i386__) || defined(__x86_64__)
#define EXCEPTION_THREAD_STATE          x86_THREAD_STATE
#define EXCEPTION_THREAD_STATE_COUNT    x86_THREAD_STATE_COUNT
#else
#error Unsupported architecture
#endif

kern_return_t catch_mach_exception_raise_state_identity(mach_port_t exception_port,
                                                        mach_port_t thread,
                                                        mach_port_t task,
                                                        exception_type_t exception,
                                                        mach_exception_data_t code,
                                                        mach_msg_type_number_t codeCnt,
                                                        int *flavor,
                                                        thread_state_t old_state,
                                                        mach_msg_type_number_t old_stateCnt,
                                                        thread_state_t new_state,
                                                        mach_msg_type_number_t *new_stateCnt)
{
    ExceptionContext * context = pthread_getspecific(exception_context_key);
    if (context == NULL) {
        return KERN_FAILURE;
    }

    exception_info_t * info = malloc(sizeof(exception_info_t));
    if (info == NULL) {
        return KERN_FAILURE;
    }
    info->exception = exception;
    info->code = code[0];
    info->code = code[1];
    info->class = context->class;
    info->handler = context->handler;

#if defined (__arm__) || defined (__arm64__)
    _STRUCT_ARM_THREAD_STATE64 * old_thread_state = (_STRUCT_ARM_THREAD_STATE64 *)(void *) old_state;
    _STRUCT_ARM_THREAD_STATE64 * new_thread_state = (_STRUCT_ARM_THREAD_STATE64 *)(void *) new_state;
    memcpy((void *) new_state, (void *) old_state, ARM_THREAD_STATE64_COUNT * 4);
    *new_stateCnt = old_stateCnt;
    new_thread_state->__lr = old_thread_state->__pc;
    arm_thread_state64_set_pc_fptr(*new_thread_state, exc_handler);
    new_thread_state->__x[0] = (__uint64_t) info;
#elif defined (__i386__) || defined(__x86_64__)
    _STRUCT_X86_THREAD_STATE64 * old_thread_state = (_STRUCT_X86_THREAD_STATE64 *)(void *) old_state;
    _STRUCT_X86_THREAD_STATE64 * new_thread_state = (_STRUCT_X86_THREAD_STATE64 *)(void *) new_state;
    // Note: stateCnt specifies the size of the state in 4-byte words.
    memcpy((void *) new_state, (void *) old_state, x86_THREAD_STATE64_COUNT * 4);
    *new_stateCnt = old_stateCnt;
    new_thread_state->__rsp -= sizeof(__uint64_t);
    __uint64_t * rsp = (__uint64_t *) new_thread_state->__rsp;
    *rsp = old_thread_state->__rip;
    new_thread_state->__rip = (__uint64_t) exc_handler;
    new_thread_state->__rdi = (__uint64_t) info;
#endif
    printf("catch_mach_exception_raise_state_identity: done\n");
    return KERN_SUCCESS;
}

static void * exception_server(void * arg) {
    ExceptionContext * context = (ExceptionContext *) arg;
    mach_msg_return_t rc;

    pthread_once(&exception_context_key_once, make_exception_context_key);
    pthread_setspecific(exception_context_key, arg);

    rc = mach_msg_server_once(mach_exc_server, MACH_MSG_SIZE_RELIABLE, context->currentExceptionPort, 0);
    if (rc != MACH_MSG_SUCCESS) {
        fprintf(stderr, "exception_handler: mach_msg_server_once failed, rc=%x\n", rc);
    }
    printf("exception_server: done\n");
    return NULL;
}

void catch_exceptions_cleanup(ExceptionContext * context) {
    if (context == NULL) {
        return;
    }
    
    if (is_exception_ports_swapped(context)) {
        thread_swap_exception_ports(mach_thread_self(),
                                    context->currentExceptionMask,
                                    0,
                                    EXCEPTION_DEFAULT,
                                    THREAD_STATE_NONE,
                                    &context->masks[0],
                                    &context->count,
                                    &context->ports[0],
                                    &context->behaviors[0],
                                    &context->flavors[0]);
    }
    
    if (context->currentExceptionPort != 0) {
        mach_port_deallocate(mach_task_self_, context->currentExceptionPort);
    }
}

int catchExceptions(ExceptionContext * context) {
   context->machStatus = mach_port_allocate(mach_task_self_,
                                             MACH_PORT_RIGHT_RECEIVE,
                                             &context->currentExceptionPort);
    if (context->machStatus != KERN_SUCCESS) {
        goto catchExceptionError;
    }

    context->machStatus = mach_port_insert_right(mach_task_self_,
                                                 context->currentExceptionPort,
                                                 context->currentExceptionPort,
                                                 MACH_MSG_TYPE_MAKE_SEND);
    if (context->machStatus != KERN_SUCCESS) {
        goto catchExceptionError;
    }
    
#if defined (__i386__) || defined(__x86_64__)
    thread_state_flavor_t native_thread_state = x86_THREAD_STATE64;
#elif defined (__arm__) || defined (__arm64__)
    thread_state_flavor_t native_thread_state = ARM_THREAD_STATE64;
#else
#error Unsupported architecture
#endif
    context->machStatus = thread_swap_exception_ports(mach_thread_self(),
                                                      context->currentExceptionMask,
                                                      context->currentExceptionPort,
                                                      EXCEPTION_STATE_IDENTITY | MACH_EXCEPTION_CODES,
                                                      native_thread_state,
                                                      &context->masks[0],
                                                      &context->count,
                                                      &context->ports[0],
                                                      &context->behaviors[0],
                                                      &context->flavors[0]);
    if (context->machStatus != KERN_SUCCESS) {
        goto catchExceptionError;
    }

    pthread_t handler_thread;
    context->pthreadStatus = pthread_create(&handler_thread, NULL, exception_server, context);
    if (context->pthreadStatus != 0) {
        goto catchExceptionError;
    }
    return;
    
catchExceptionError:
    catch_exceptions_cleanup(context);
    return;
}

//
@implementation MachException
{
    //@private
    exception_mask_t currentExceptionMask;
    mach_port_t currentExceptionPort;
    mach_msg_type_number_t count;
    exception_mask_t masks[EXC_TYPES_COUNT];
    mach_port_t ports[EXC_TYPES_COUNT];
    exception_behavior_t behaviors[EXC_TYPES_COUNT];
    thread_state_flavor_t flavors[EXC_TYPES_COUNT];
    bool success;
}

- (id) init
{
    self = [super init];
    success = false;
    return self;
}

- (void) dealloc
{
    if (success) {
        thread_swap_exception_ports(mach_thread_self(),
                                    currentExceptionMask,
                                    0,
                                    EXCEPTION_DEFAULT,
                                    THREAD_STATE_NONE,
                                    masks,
                                    &count,
                                    ports,
                                    behaviors,
                                    flavors);
        mach_port_deallocate(mach_task_self_, currentExceptionPort);
    }
}

- (BOOL) prepareToListenForException: (exception_mask_t) exceptionMask
                               error: (NSError **) error;
{
    kern_return_t code;
    
    code = mach_port_allocate(mach_task_self_,
                                MACH_PORT_RIGHT_RECEIVE,
                                &currentExceptionPort);
    if (code != KERN_SUCCESS) {
        *error = [NSError errorWithDomain: NSMachErrorDomain code:code userInfo: nil];
        return false;
    }
    
    code = mach_port_insert_right(mach_task_self_,
                                    currentExceptionPort,
                                    currentExceptionPort,
                                    MACH_MSG_TYPE_MAKE_SEND);
    if (code != KERN_SUCCESS) {
        *error = [NSError errorWithDomain: NSMachErrorDomain code:code userInfo: nil];
        return false;
    }
    
#if defined (__i386__) || defined(__x86_64__)
    thread_state_flavor_t nativeThreadState = x86_THREAD_STATE64;
#elif defined (__arm__) || defined (__arm64__)
    thread_state_flavor_t nativeThreadState = ARM_THREAD_STATE64;
#else
#error Unsupported architecture
#endif
    code = thread_swap_exception_ports(mach_thread_self(),
                                         currentExceptionMask,
                                         currentExceptionPort,
                                         EXCEPTION_STATE_IDENTITY | MACH_EXCEPTION_CODES,
                                         nativeThreadState,
                                         masks,
                                         &count,
                                         ports,
                                         behaviors,
                                         flavors);
    if (code != KERN_SUCCESS) {
        *error = [NSError errorWithDomain: NSMachErrorDomain code:code userInfo: nil];
        return false;
    }
    
    success = true;
    *error = nil;
    return true;
}

- (BOOL) listenForExceptionWithError: (NSError **) error
                          completion: (void(^)(exception_type_t type,
                                               mach_exception_code_t code,
                                               mach_exception_subcode_t subcode)) completion;
{
    kern_return_t code;
    
//    code = mach_msg_server_once(mach_exc_server, MACH_MSG_SIZE_RELIABLE, context->currentExceptionPort, 0);
//    if (code != MACH_MSG_SUCCESS) {
//        return
//    }

}
@end
