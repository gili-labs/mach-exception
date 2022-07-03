//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// mach_exceptions.h
// Created by Patrick Gili on 5/20/22.
//

#import <Foundation/Foundation.h>
#ifdef __APPLE__
#import "TargetConditionals.h"
#if TARGET_OS_OSX || TARGET_OS_IOS

#import <mach/mach.h>

extern bool _swift_disableExclusivityChecking;
extern bool _swift_reportFatalErrorsToDebugger;

NS_ASSUME_NONNULL_BEGIN

NSErrorDomain const ExceptionErrorDomain = @"com.gili-labs.exceptions";
NSErrorUserInfoKey const ExceptionCode = @"code";
NSErrorUserInfoKey const ExceptionSubcode = @"subcode";

@interface MachException: NSObject

@property exception_mask_t mask;

- (instancetype _Nullable) initWithMask: (exception_mask_t) mask
                                  error: (NSError **) error;

- (void) dealloc;

- (BOOL) listenWithTimeout: (mach_msg_timeout_t) timeout
                     error: (NSError **) error;

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
} ExceptionContext;

@interface MException: NSObject

- (instancetype _Nullable) init;

- (void) dealloc;

- (BOOL) prepareToCatchWithExceptionContext: (ExceptionContext *) context
                                      error: (NSError **) error;

- (BOOL) catchExceptionWithExceptionContext: (ExceptionContext *) context
                                      error: (NSError **) error;

- (BOOL) listenOnPort: (mach_port_t) port
              timeout: (mach_msg_timeout_t) timeout
                error: (NSError **) error;

- (BOOL) cleanup: (ExceptionContext *) context;

@end

NS_ASSUME_NONNULL_END

#endif /* TARGET_OS_OSX || TARGET_OS_IOS */
#endif /* __APPLE__ */
