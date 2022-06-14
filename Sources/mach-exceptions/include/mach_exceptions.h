//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// mach_exceptions.h
// Created by Patrick Gili on 5/20/22.
//

#import <Foundation/Foundation.h>
//#ifdef __APPLE__
//#import "TargetConditionals.h"
#if TARGET_OS_OSX || TARGET_OS_IOS

#import <mach/mach.h>

extern bool _swift_disableExclusivityChecking;
extern bool _swift_reportFatalErrorsToDebugger;

NS_ASSUME_NONNULL_BEGIN

@interface MachException: NSObject

- (id _Nonnull) init;

- (void) dealloc;

- (BOOL) prepareToListenForException: (exception_mask_t) exceptionMask
                               error: (NSError **) error;

- (BOOL) listenForExceptionWithError: (NSError **) error
                          completion: (void(^)(exception_type_t type,
                                               mach_exception_code_t code,
                                               mach_exception_subcode_t subcode)) completion;

@end

/// A type containing information needed by the thread executing the mach_exc_server.
typedef struct {
    /// The exception mask for the current exception port.
    exception_mask_t currentExceptionMask;
    
    /// The exception port on which the mach_exc_server uses to receive exception messages.
    mach_port_t currentExceptionPort;
    
    /// Before calling thread_swap_exception_ports, the value of this field must be set to the size of the
    /// subsequent arrays.
    ///
    /// After calling thread_swap_exception_ports, the value of this field reflects the number of sets
    /// returned.
    mach_msg_type_number_t count;
    
    /// The exception masks returned by thread_swap_exception_ports.
    exception_mask_t masks[EXC_TYPES_COUNT];
    
    /// The exception ports corresponding to each exception mask.
    mach_port_t ports[EXC_TYPES_COUNT];
    
    /// The type of exception messages sent for each exception mask.
    exception_behavior_t behaviors[EXC_TYPES_COUNT];
    
    /// The type of state sent for each exception message.
    thread_state_flavor_t flavors[EXC_TYPES_COUNT];
    
    /// Indicates the kernel return status. KERN_SUCCESS if no error occurred.
    kern_return_t machStatus;
    
    /// Indicates the pthread_create return status. `0` if no error occurred.
    int pthreadStatus;
    
    /// The object containing the callback.
    void * class;

    /// The callback invoked when the Mach excpetion server receives an exception.
    void (* handler)(void *, exception_type_t, mach_exception_code_t, mach_exception_subcode_t);
} ExceptionContext;

int catchExceptions(ExceptionContext * context);

void catch_exceptions_cleanup(ExceptionContext * context);

NS_ASSUME_NONNULL_END

#endif /* TARGET_OS_OSX || TARGET_OS_IOS */
//#endif /* __APPLE__ */
