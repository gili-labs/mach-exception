//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach_exception_helper.m
// Created by Patrick Gili on 4/12/22.
//

#import <Foundation/Foundation.h>
#import <mach/kern_return.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <pthread/pthread.h>
#include "mach_msg_server_once.h"
#include "mach_excServer.h"
#include "mach_exception_helper.h"

NSErrorDomain const MachExceptionErrorDomain = @"com.gili-labs.machException";
NSErrorUserInfoKey const MachExceptionType = @"type";
NSErrorUserInfoKey const MachExceptionCode = @"code";
NSErrorUserInfoKey const MachExceptionSubcode = @"subcode";

@interface MachException: NSException
@property exception_type_t type;
@property mach_exception_data_type_t code;
@property mach_exception_data_type_t subcode;
@end

@implementation MachException
@end

// MARK: - exc_handler

static void exc_handler(exception_type_t type, mach_exception_data_type_t code, mach_exception_data_t subcode) {
    MachException * mach_exception = [[MachException alloc]
                                      initWithName: MachExceptionErrorDomain
                                      reason: @"Mach exception"
                                      userInfo: nil];
    mach_exception.type = type;
    mach_exception.code = code;
    mach_exception.subcode = subcode;
    @throw mach_exception;
}

// MARK: - catch_mach_exception_raise
kern_return_t catch_mach_exception_raise(mach_port_t exception_port,
                                         mach_port_t thread,
                                         mach_port_t task,
                                         exception_type_t exception,
                                         mach_exception_data_t code,
                                         mach_msg_type_number_t codeCnt) {
    fprintf(stderr, "catch_mach_exception_raise called\n");
    return KERN_NOT_SUPPORTED;
}

// MARK: - catch_mach_exception_raise_state

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

// MARK: - catch_mach_exception_raise_state_identity

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
#if defined (__arm__) || defined (__arm64__)
    _STRUCT_ARM_THREAD_STATE64 * old_thread_state = (_STRUCT_ARM_THREAD_STATE64 *)(void *) old_state;
    _STRUCT_ARM_THREAD_STATE64 * new_thread_state = (_STRUCT_ARM_THREAD_STATE64 *)(void *) new_state;
    memcpy((void *) new_state, (void *) old_state, ARM_THREAD_STATE64_COUNT * 4);
    *new_stateCnt = old_stateCnt;
    new_thread_state->__lr = old_thread_state->__pc;
    arm_thread_state64_set_pc_fptr(*new_thread_state, exc_handler);
    new_thread_state->__x[0] = (__uint64_t) exception;
    new_thread_state->__x[1] = (__uint64_t) code[0];
    new_thread_state->__x[2] = (__uint64_t) code[1];
    
#elif defined (__i386__) || defined(__x86_64__)
    _STRUCT_X86_THREAD_STATE64 * old_thread_state = (_STRUCT_X86_THREAD_STATE64 *)(void *) old_state;
    _STRUCT_X86_THREAD_STATE64 * new_thread_state = (_STRUCT_X86_THREAD_STATE64 *)(void *) new_state;
    // Note: stateCnt specifies the size of the state in 4-byte words.
    memcpy((void *) new_state, (void *) old_state, x86_THREAD_STATE64_COUNT * 4);
    *new_stateCnt = old_stateCnt;
    // NEED TO TEST THIS ON A MACHINE WITH AN x86_64 PROCESSOR
    new_thread_state->__rsp -= sizeof(__uint64_t);
    __uint64_t * rsp = (__uint64_t *) new_thread_state->__rsp;
    *rsp = old_thread_state->__rip;
    new_thread_state->__rip = (__uint64_t) exc_handler;
    new_thread_state->__rdi = (__uint64_t) exception;
    new_thread_state->__rsi = (__uint64_t) code[0];
    new_thread_state->__rdx = (__uint64_t) code[1];
#endif
    return KERN_SUCCESS;
}

// MARK: - MachExceptionHelperDependenciesDefault

@implementation MachExceptionHelperDependenciesDefault

- (BOOL) super_init_fail
{
    return false;
}

- (kern_return_t) port_allocate: (ipc_space_t) space
                          right: (mach_port_right_t) right
                           name: (mach_port_name_t *) name
{
    return mach_port_allocate(space, right, name);
}

- (kern_return_t) port_insert_right: (ipc_space_t) space
                               name: (mach_port_name_t) name
                               port: (mach_port_t) poly
                           polyPoly: (mach_msg_type_name_t) polyPoly
{
    return mach_port_insert_right(space, name, poly, polyPoly);
}

- (kern_return_t) swap_exception_ports: (thread_t) thread
                        exception_mask: (exception_mask_t) exception_mask
                              new_port: (mach_port_t) new_port
                          new_behavior: (exception_behavior_t) new_behavior
                            new_flavor: (thread_state_flavor_t) new_flavor
                                 masks: (exception_mask_array_t) masks
                              CountCnt: (mach_msg_type_number_t *) CountCnt
                                 ports: (exception_port_array_t) ports
                             behaviors: (exception_behavior_array_t) behaviors
                               flavors: (thread_state_flavor_array_t) flavors
{
    return thread_swap_exception_ports(thread,
                                       exception_mask,
                                       new_port,
                                       new_behavior,
                                       new_flavor,
                                       masks,
                                       CountCnt,
                                       ports,
                                       behaviors,
                                       flavors);
}

@end

// MARK: - MachExceptionHelper

@implementation MachExceptionHelper
{
    mach_port_t port;
    mach_msg_type_number_t count;
    exception_mask_t masks[EXC_TYPES_COUNT];
    mach_port_t ports[EXC_TYPES_COUNT];
    exception_behavior_t behaviors[EXC_TYPES_COUNT];
    thread_state_flavor_t flavors[EXC_TYPES_COUNT];
    id<MachExceptionHelperDependencies> dependencies;
}

- (instancetype _Nullable) initWithMask: (exception_mask_t) mask
                           dependencies: (id<MachExceptionHelperDependencies>) helper_dependencies
                                  error: (NSError **) error
{
    dependencies = helper_dependencies;
    if ([dependencies super_init_fail]) {
        return nil;
    }
    self = [super init];
    if (self) {
        _mask = mask;
        
        kern_return_t code;
        code = [dependencies port_allocate: mach_task_self_
                                     right: MACH_PORT_RIGHT_RECEIVE
                                      name: &port];
        if (code != KERN_SUCCESS) {
            *error = [NSError errorWithDomain: NSMachErrorDomain code:code userInfo: nil];
            return nil;
        }
        
        code = [dependencies port_insert_right: mach_task_self_
                                          name: port
                                          port: port
                                      polyPoly: MACH_MSG_TYPE_MAKE_SEND];
        if (code != KERN_SUCCESS) {
            mach_port_deallocate(mach_task_self_, port);
            *error = [NSError errorWithDomain: NSMachErrorDomain code:code userInfo: nil];
            return nil;
        }
        
#if defined (__i386__) || defined(__x86_64__)
        thread_state_flavor_t nativeThreadState = x86_THREAD_STATE64;
#elif defined (__arm__) || defined (__arm64__)
        thread_state_flavor_t nativeThreadState = ARM_THREAD_STATE64;
#else
#error Unsupported architecture
#endif
        mach_msg_type_number_t count = EXC_TYPES_COUNT;
        code = [dependencies swap_exception_ports: mach_thread_self()
                                   exception_mask: self.mask
                                         new_port: port
                                     new_behavior: EXCEPTION_STATE_IDENTITY | MACH_EXCEPTION_CODES
                                       new_flavor: nativeThreadState
                                            masks: masks
                                         CountCnt: &count
                                            ports: ports
                                        behaviors: behaviors
                                          flavors: flavors];
        if (code != KERN_SUCCESS) {
            mach_port_deallocate(mach_task_self_, port);
            *error = [NSError errorWithDomain: NSMachErrorDomain code:code userInfo: nil];
            return nil;
        }
        
        *error = nil;
    }
    return self;
}

- (void) dealloc
{
    thread_swap_exception_ports(mach_thread_self(),
                                self.mask,
                                0,
                                EXCEPTION_DEFAULT,
                                THREAD_STATE_NONE,
                                masks,
                                &count,
                                ports,
                                behaviors,
                                flavors);
    
    mach_port_deallocate(mach_task_self_, port);
}

- (BOOL) listenWithTimeout: (mach_msg_timeout_t) timeout
                     error: (NSError **) error
{
    mach_msg_return_t code;
    code = mach_msg_server_once_with_timeout(mach_exc_server,
                                             MACH_MSG_SIZE_RELIABLE,
                                             port,
                                             MACH_RCV_TIMEOUT,
                                             timeout);
    if (code != MACH_MSG_SUCCESS) {
        *error = [NSError errorWithDomain: NSMachErrorDomain code: code userInfo: nil];
        return false;
    }
    
    *error = nil;
    return true;
}

- (BOOL) perform: (__attribute__((noescape)) void(^)(void)) tryBlock
         finally: (__attribute__((noescape)) void(^)(void)) finallyBlock
           error: (__autoreleasing NSError **) error
{
    NSException * exception;
    @try {
        tryBlock();
        return YES;
    } @catch (MachException * exception) {
        NSDictionary * userInfo = @{
            MachExceptionCode : [NSNumber numberWithLongLong: exception.code],
            MachExceptionSubcode : [NSNumber numberWithLongLong: exception.subcode]
        };
        *error = [NSError errorWithDomain: exception.name code: exception.type userInfo: userInfo];
        return NO;
    } @catch (id ue) {
        *error = [NSError errorWithDomain: exception.name code: 0 userInfo: nil];
        return NO;
    } @finally {
        finallyBlock();
    }
}

@end
