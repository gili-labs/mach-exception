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
#import <mach/port.h>
#import <mach/thread_act.h>
#import <kern/exc_resource.h>
#import <kern/exc_guard.h>

// A Boolean-value that disables Swift's exclusivity checking (see the following Swift Blog entry
// for further details: https://www.swift.org/blog/swift-5-exclusivity/).
FOUNDATION_EXPORT bool _swift_disableExclusivityChecking;

// A Boolean-value that enables Swift's reporting of fatal errors to the debugger. This setting is not
// documented anywhere, rather defined in Swift's standard library.
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

// MARK: - MachExceptionHelperDependencies

// A type defining MachExceptionHelper's dependencies. This type supports content dependency injection
// of these dependencies into MachExceptionHelper, thereby enabling better unit test code coverage.
@protocol MachExceptionHelperDependencies

- (BOOL) super_init_fail;

- (kern_return_t) port_allocate: (ipc_space_t) space
                          right: (mach_port_right_t) right
                           name: (mach_port_name_t *) name;

- (kern_return_t) port_insert_right: (ipc_space_t) space
                               name: (mach_port_name_t) name
                               port: (mach_port_t) poly
                           polyPoly: (mach_msg_type_name_t) polyPoly;

- (kern_return_t) swap_exception_ports: (thread_t) thread
                        exception_mask: (exception_mask_t) exception_mask
                              new_port: (mach_port_t) new_port
                          new_behavior: (exception_behavior_t) new_behavior
                            new_flavor: (thread_state_flavor_t) new_flavor
                                 masks: (exception_mask_array_t) masks
                              CountCnt: (mach_msg_type_number_t *) CountCnt
                                 ports: (exception_port_array_t) ports
                             behaviors: (exception_behavior_array_t) behaviors
                               flavors: (thread_state_flavor_array_t) flavors;

@end

// MARK: - MachExceptionHelperDependenciesDefault

// A type defining MachExceptionHelper's default dependencies. Note, this type conforms to
// MachExceptionHelperDependencies.
@interface MachExceptionHelperDependenciesDefault: NSObject<MachExceptionHelperDependencies>

- (BOOL) super_init_fail;

- (kern_return_t) port_allocate: (ipc_space_t) space
                          right: (mach_port_right_t) right
                           name: (mach_port_name_t *) name;

- (kern_return_t) port_insert_right: (ipc_space_t) space
                               name: (mach_port_name_t) name
                               port: (mach_port_t) poly
                           polyPoly: (mach_msg_type_name_t) polyPoly;

- (kern_return_t) swap_exception_ports: (thread_t) thread
                        exception_mask: (exception_mask_t) exception_mask
                              new_port: (mach_port_t) new_port
                          new_behavior: (exception_behavior_t) new_behavior
                            new_flavor: (thread_state_flavor_t) new_flavor
                                 masks: (exception_mask_array_t) masks
                              CountCnt: (mach_msg_type_number_t *) CountCnt
                                 ports: (exception_port_array_t) ports
                             behaviors: (exception_behavior_array_t) behaviors
                               flavors: (thread_state_flavor_array_t) flavors;

@end

// MARK: - MachExceptionHelper

/// An object supporting the Swift MachException class.
@interface MachExceptionHelper: NSObject

/// The bit mask specifying the Mach exceptions this helper object listens for.
@property (readonly) exception_mask_t mask;

/// Create and initialize a Mach exception helper object.
///
/// - Parameters:
///   - mask: The bit mask specifying the Mach exceptions this helper object listens for.
///   - dependencies: An instance defining the dependencies required by this instance.
///   - error: The error that occurred during the attempt to create and initialize a Mach
///     exception helper object.
///
/// - Returns: A Mach exception helper object, or `nil` if an error occurred during the
///   creation and initialization fo the Mach exception.
- (instancetype _Nullable) initWithMask: (exception_mask_t) mask
                           dependencies: (id<MachExceptionHelperDependencies>) dependencies
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

// Expose access to this function strictly for unit testing code coverage.
kern_return_t catch_mach_exception_raise(mach_port_t exception_port,
                                         mach_port_t thread,
                                         mach_port_t task,
                                         exception_type_t exception,
                                         mach_exception_data_t code,
                                         mach_msg_type_number_t codeCnt);

// Expose access to this function strictly for unit testing code coverage.
kern_return_t catch_mach_exception_raise_state(mach_port_t exception_port,
                                               exception_type_t exception,
                                               const mach_exception_data_t code,
                                               mach_msg_type_number_t codeCnt,
                                               int *flavor,
                                               const thread_state_t old_state,
                                               mach_msg_type_number_t old_stateCnt,
                                               thread_state_t new_state,
                                               mach_msg_type_number_t *new_stateCnt);

NS_ASSUME_NONNULL_END

#endif /* TARGET_OS_OSX || TARGET_OS_IOS */
#endif /* __APPLE__ */
