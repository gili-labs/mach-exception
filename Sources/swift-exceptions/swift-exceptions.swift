//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// swift-exceptions.swift
// Created by Patrick Gili on 5/17/22.
//

import Foundation
import Darwin
import mach_exceptions

public struct ExceptionTypes: OptionSet {
    
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let badAccess        = ExceptionTypes(rawValue: 1 << EXC_BAD_ACCESS)
    public static let badInstruction   = ExceptionTypes(rawValue: 1 << EXC_BAD_INSTRUCTION)
    public static let arithmetic       = ExceptionTypes(rawValue: 1 << EXC_ARITHMETIC)
    public static let emulation        = ExceptionTypes(rawValue: 1 << EXC_EMULATION)
    public static let software         = ExceptionTypes(rawValue: 1 << EXC_SOFTWARE)
    public static let breakpoint       = ExceptionTypes(rawValue: 1 << EXC_BREAKPOINT)
    public static let syscall          = ExceptionTypes(rawValue: 1 << EXC_SYSCALL)
    public static let machSyscall      = ExceptionTypes(rawValue: 1 << EXC_MACH_SYSCALL)
    public static let rpcAlert         = ExceptionTypes(rawValue: 1 << EXC_RPC_ALERT)
    public static let crash            = ExceptionTypes(rawValue: 1 << EXC_CRASH)
    public static let resource         = ExceptionTypes(rawValue: 1 << EXC_RESOURCE)
    public static let `guard`          = ExceptionTypes(rawValue: 1 << EXC_GUARD)
    public static let corpseNotify     = ExceptionTypes(rawValue: 1 << EXC_CORPSE_NOTIFY)
    
    public var exceptionMask: exception_mask_t {
        exception_mask_t(rawValue)
    }
}

func getClassPointer<T: AnyObject>(_ object: T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Unmanaged.passUnretained(object).toOpaque())
}

public class Exception {
    
    public enum ExceptionType: Error {
        case badAccess(mach_exception_code_t, mach_exception_subcode_t)
        case badInstruction(mach_exception_code_t, mach_exception_subcode_t)
        case arithmetic(mach_exception_code_t, mach_exception_subcode_t)
        case emulation(mach_exception_code_t, mach_exception_subcode_t)
        case software(mach_exception_code_t, mach_exception_subcode_t)
        case breakpoint(mach_exception_code_t, mach_exception_subcode_t)
        case syscall(mach_exception_code_t, mach_exception_subcode_t)
        case machSyscall(mach_exception_code_t, mach_exception_subcode_t)
        case rpcAlert(mach_exception_code_t, mach_exception_subcode_t)
        case crash(mach_exception_code_t, mach_exception_subcode_t)
        case resource(mach_exception_code_t, mach_exception_subcode_t)
        case `guard`(mach_exception_code_t, mach_exception_subcode_t)
        case corpseNotify(mach_exception_code_t, mach_exception_subcode_t)
    }

    var handler: ((exception_type_t, mach_exception_code_t, mach_exception_subcode_t) -> Void)?
    
    public func catching(types: ExceptionTypes,
                         handler: @escaping (exception_type_t, mach_exception_code_t, mach_exception_subcode_t) -> Void,
                         closure: @escaping () -> Void)
    {
        let previousExclusivity = _swift_disableExclusivityChecking
        let previousReporting = _swift_reportFatalErrorsToDebugger
        _swift_disableExclusivityChecking = true
        _swift_reportFatalErrorsToDebugger = false
        defer {
            _swift_reportFatalErrorsToDebugger = previousReporting
            _swift_disableExclusivityChecking = previousExclusivity
        }

        self.handler = handler
        
        var context = ExceptionContext(currentExceptionMask: types.exceptionMask,
                                       currentExceptionPort: 0,
                                       count: 0,
                                       masks: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       ports: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       behaviors: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       flavors: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       machStatus: KERN_SUCCESS,
                                       pthreadStatus: 0,
                                       class: getClassPointer(self))
        { (classPointer, type, code, subcode) -> Void in
            let this = Unmanaged<Exception>.fromOpaque(classPointer).takeUnretainedValue()
            this.handler!(type, code, subcode)
        }
        defer {
            print("DEFERRING")
            catch_exceptions_cleanup(&context)
        }
        
        catchExceptions(&context)
        closure()
    }
}
