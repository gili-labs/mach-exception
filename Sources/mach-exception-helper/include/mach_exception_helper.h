//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach_exception_helper.h
// Created by Patrick Gili on 5/20/22.
//

#import <Foundation/Foundation.h>
#ifdef __APPLE__
#import "TargetConditionals.h"
#if TARGET_OS_OSX || TARGET_OS_IOS

#import <mach/mach.h>
#import <kern/exc_resource.h>
#import <kern/exc_guard.h>

FOUNDATION_EXPORT bool _swift_disableExclusivityChecking;
FOUNDATION_EXPORT bool _swift_reportFatalErrorsToDebugger;

NS_ASSUME_NONNULL_BEGIN

/// The predefined domain identifying a Mach exception.
FOUNDATION_EXPORT NSErrorDomain const MachExceptionErrorDomain;

/// A key identifying a Mach exception's type in an a NSError object's userinfo dictionary.
FOUNDATION_EXPORT NSErrorUserInfoKey const MachExceptionType;

/// A key identifying a Mach exception's code in an a NSError object's userinfo dictionary.
FOUNDATION_EXPORT NSErrorUserInfoKey const MachExceptionCode;

/// A key identifying a Mach exception's subcode in an a NSError object's userinfo dictionary.
FOUNDATION_EXTERN NSErrorUserInfoKey const MachExceptionSubcode;

/// An object supporting the Swift MachException class.
@interface MachExceptionHelper: NSObject

/// The bit mask specifying the Mach exceptions this helper object listens for.
@property (readonly) exception_mask_t mask;

/// Create and initialize a Mach exception helper object.
///
/// - Parameters:
///   - mask: The bit mask specifying the Mach exceptions this helper object listens for.
///   - error: The error that occurred during the attempt to create and initialize a Mach
///     exception helper object.
///
/// - Returns: A Mach exception helper object, or `nil` if an error occurred during the
///   creation and initialization fo the Mach exception.
- (instancetype _Nullable) initWithMask: (exception_mask_t) mask
                                  error: (NSError **) error;

/// Releases any resources created for this Mach exception helper.
- (void) dealloc;

/// Listen for Mach exceptions.
///
/// - Parameters:
///   - timeout: The number of milliseconds this Mach exception helper listens before returning.
///   - error: The error that occurred during the attempt to start the listener.
///
/// - Returns: A Boolean-value indicating whether the listner was successful (i.e., it
///   received a Mach exception, or the listener failed, either because the kernel could
///   not start the listener or a timeout occurred.
- (BOOL) listenWithTimeout: (mach_msg_timeout_t) timeout
                     error: (NSError **) error;

/// Try an operation, catching Mach exceptions.
///
/// - Parameters:
///   - operation: The operation performed while listening for Mach exceptions.
///   - finally: A closure executed after the the `operation` executes to completion, or
///     after catching a Mach exception.
///   - error: An error representing the Mach exception, if one was caught.
///
/// - Returns: A Boolean-value indicating whether `operation` executed to completion.
///   If not, `error` indicates the Mach exception caught when performing `operation`.s
- (BOOL) perform: (__attribute__((noescape)) void(^)(void)) operation
         finally: (__attribute__((noescape)) void(^)(void)) finally
           error: (__autoreleasing NSError **) error;

@end

__uint64_t getThreadId();

NS_ASSUME_NONNULL_END

#endif /* TARGET_OS_OSX || TARGET_OS_IOS */
#endif /* __APPLE__ */
