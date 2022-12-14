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

///
public func withUnsafeMachException(types: MachExceptionTypes,
                                    listenerTimeout timeout: mach_msg_timeout_t = 10,
                                    operation: @escaping () -> (),
                                    finally: @escaping () -> () = { () in }) throws
{
    let helper = try MachExceptionHelper(mask: types.exceptionMask)
    
    let previousExclusivity = _swift_disableExclusivityChecking
    let previousReporting = _swift_reportFatalErrorsToDebugger
    _swift_disableExclusivityChecking = true
    _swift_reportFatalErrorsToDebugger = false
    
    defer {
        _swift_reportFatalErrorsToDebugger = previousReporting
        _swift_disableExclusivityChecking = previousExclusivity
    }

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
