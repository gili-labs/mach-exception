//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach-exception.swift
// Created by Patrick Gili on 5/17/22.
//

import Foundation
import Darwin
import mach_exception_helper

/// Execute an operation, catching Mach exceptions of specified types.
///
/// Warning!
/// Throwing an exception through a Swift frame can have undesirable side effects, such as leaking memory. The reason
/// for this is Swift wasn't designed to handle exceptions, and hence stack unwinding becauses an issue due to language
/// features. For example, simple stack unwinding ignores executing defer statements defined in the scope of a frame.
/// Sometimes, it is possible to perform the necessary clean up in the finally block. However, there is no guarantee
/// this works consistently with subsequent releases of the Swift language.
///
/// - Parameters:
///   - types: The Mach exception types the function will catch, if thrown.
///   - listenerTimeout: The frequency (in milliseconds) that the exception listener checks for cancellation, which
///     occurs when the operation completes.
///   - dependencies: The dependencies required by the Mach exception helper. By default, the function creates the
///     necessary default dependencies. This parameter has the intent of providing dependency injection by software
///     unit tests.
///   - operation: A closure executed by the function that may throw Mach exceptions.
///   - finally: A "finally block" executed after the operation and any subsequent exception have executed.
///
/// - Throws: If the operation throws an Mach exception, then the function throws a `MachExceptionError`, which
///   specifies the Mach exception type, the associated code, and associated sub-code. It is possible for the
///   function to throw an `NSError` corresponding to errors returned by the Mach exception helper.
public func withUnsafeMachException(types: MachExceptionTypes,
                                    listenerTimeout timeout: mach_msg_timeout_t = 10,
                                    dependencies: MachExceptionHelperDependencies = MachExceptionHelperDependenciesDefault(),
                                    operation: @escaping () -> (),
                                    finally: @escaping () -> () = { () in }) throws
{
    // Create a Mach exception helper to listen for the specified Mach exception types.
    let helper = try MachExceptionHelper(mask: types.exceptionMask, dependencies: dependencies)
    
    // Save the current configuration flags for exclusivity checking and fatal error reporting.
    let previousExclusivity = _swift_disableExclusivityChecking
    let previousReporting = _swift_reportFatalErrorsToDebugger
    
    // Disable exclusivity checking and fatal error reporting.
    _swift_disableExclusivityChecking = true
    _swift_reportFatalErrorsToDebugger = false
    
    // Before the function returns, restore the configuration flags for exclusivity checking and fatal error reporting.
    defer {
        _swift_reportFatalErrorsToDebugger = previousReporting
        _swift_disableExclusivityChecking = previousExclusivity
    }

    // Start the listener task, which runs concurrently with the rest of this function. The listener task consists of
    // a loop that executes until the task is cancelled. On each iteration of the loop, the listener task invokes the
    // Mach exception handler's listener method, which can result in three cases:
    //
    //   - The Mach exception handler's listener method received a Mach exception, in which case it done.
    //
    //   - The Mach exception handler's listener method time's out, then the task simply checks if it is cancelled.
    //     If not, then it continues listening.
    //
    //   - The Mach exception handler's listener method encountered an error, which causes the task to throw the error.
    //
    // FIXIT: The function does nothing with errors thrown by this task, which can result in undesirable behavior.
    // Ideally, if the task throws an error, then it is desirable to terminate the operation and have this function
    // rethrow the error. However, there are competing requirements at play. It isn't necessarily desirable for the
    // operation to support asynchronous semantics, not to mention cancellation semantics. It may become necessary to
    // spawn the operation is in own thread, which this thread could terminate.
    let listenerTask = Task {
        while Task.isCancelled == false {
            do {
                try helper.listen(withTimeout: timeout)
                break
            } catch let error as NSError where error.code == MACH_RCV_TIMED_OUT {
                continue
            } catch let error as NSError {
                throw error
            }
        }
    }
    
    // Perform the operation, which results in the following cases:
    //
    //   - The operation completes without throwing a Mach exception. In this case, the "finally block" excecutes and
    //     the listener task is cancelled.
    //
    //   - The operation throws a Mach exception. In this case, this function checks if the exception is indeed a Mach
    //     exception, in which case it rethrows it. It isn't necessary to worry about the Mach exception helper's
    //     listener, as in this case it will already have terminated.
    //
    //   - The operation throws some other exception, which causes the function to log the error and return.
    do {
        try helper.perform {
            operation()
        } finally: {
            finally()
        }
        listenerTask.cancel()
    } catch let error as NSError where error.domain == MachExceptionErrorDomain {
        guard let machExceptionError = MachExceptionError(error) else {
            print("Unhandled exception") // FIXIT: Fix this to use log, instead of print
            return
        }
        throw machExceptionError
    }
}
