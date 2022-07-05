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
import swift_exceptions_tls
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

public enum ExceptionError: Error {
    case badAccess(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case badInstruction(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case arithmetic(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case emulation(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case software(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case breakpoint(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case syscall(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case machSyscall(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case rpcAlert(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case crash(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case resource(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case `guard`(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    case corpseNotify(code: mach_exception_code_t, subcode: mach_exception_subcode_t)
    
    internal init?(_ error: Error) {
        let error = error as NSError
        guard error.domain == "com.gili-labs.exceptions" else {
            return nil
        }

        let type: exception_type_t = exception_type_t(error.code)
        
        guard let code = error.userInfo["code"] as? mach_exception_code_t else {
            return nil
        }
        
        guard let subcode = error.userInfo["subcode"] as? mach_exception_subcode_t else {
            return nil
        }

        switch type {
        case EXC_BAD_ACCESS: self = .badAccess(code: code, subcode: subcode)
        case EXC_BAD_INSTRUCTION: self = .badInstruction(code: code, subcode: subcode)
        case EXC_ARITHMETIC: self = .arithmetic(code: code, subcode: subcode)
        case EXC_EMULATION: self = .emulation(code: code, subcode: subcode)
        case EXC_SOFTWARE: self = .software(code: code, subcode: subcode)
        case EXC_BREAKPOINT: self = .breakpoint(code: code, subcode: subcode)
        case EXC_SYSCALL: self = .syscall(code: code, subcode: subcode)
        case EXC_MACH_SYSCALL: self = .machSyscall(code: code, subcode: subcode)
        case EXC_RPC_ALERT: self = .rpcAlert(code: code, subcode: subcode)
        case EXC_CRASH: self = .crash(code: code, subcode: subcode)
        case EXC_RESOURCE: self = .resource(code: code, subcode: subcode)
        case EXC_GUARD: self = .`guard`(code: code, subcode: subcode)
        case EXC_CORPSE_NOTIFY: self = .corpseNotify(code: code, subcode: subcode)
        default: return nil
        }
    }
}

class Exception<OperationResult> {

    internal let machException: MachException
    internal let listenerTimeout: mach_msg_timeout_t
    internal var error: Error?
     
    let previousExclusivity: Bool
    let previousReporting: Bool
     
    public init(exceptions: ExceptionTypes, listenerTimeout: mach_msg_timeout_t = 10) throws {
        self.machException = try MachException(mask: exceptions.exceptionMask)
        self.listenerTimeout = listenerTimeout

        previousExclusivity = _swift_disableExclusivityChecking
        previousReporting = _swift_reportFatalErrorsToDebugger
        _swift_disableExclusivityChecking = true
        _swift_reportFatalErrorsToDebugger = false
    }
    
    deinit {
        _swift_reportFatalErrorsToDebugger = previousReporting
        _swift_disableExclusivityChecking = previousExclusivity
    }
     
    internal enum ChildTask<T> {
        case listener(())
        case operation(T)
    }

    public func withCatching(operation: @escaping () -> OperationResult) async throws -> OperationResult
    {
        return try await ExceptionTLS.$completionHandler.withValue(self.onException) {
            return try await withThrowingTaskGroup(of: ChildTask<OperationResult>.self) { group in
                var operationResult: OperationResult?
                
                group.addTask { [self] in
                    return .listener(try listen(withTimeout: listenerTimeout))
                }
                
                group.addTask {
                    .operation(operation())
                }
                
                for try await task in group {
                    switch task {
                    case .listener:
                        print("LISTENER DONE")
                        //group.cancelAll()
                        
                    case .operation(let result):
                        print("OPERATION DONE")
                        //group.cancelAll()
                        operationResult = result
                    }
                }
                
                return operationResult!
            }
        }
    }
    
    internal func listen(withTimeout timeout: mach_msg_timeout_t) throws {
        while Task.isCancelled == false {
            do {
                print("starting to listen")
                try machException.listen(withTimeout: timeout)
                print("listener done")
                break
            } catch let error as NSError where error.code == MACH_RCV_TIMED_OUT {
                print("listener timeout")
                continue
            } catch let error as NSError {
                print("listener failed")
                throw error
            }
        }
    }
    
    internal func onException(_ error: Error) -> Void {
        print("GOT HERE, GOT HERE, GOT HERE!!!")
        self.error = error
    }
}

public class OldException2 {

    var listener: Task<(), Error>?
    var operation: Task<(), Error>?
    var error: Error?

    public func exceptionHandler(_ error: Error) -> Void {
//        print("GOT HERE, GOT HERE, GOT HERE!!!")
//        print(error as NSError)
        self.error = error
        print(Thread.callStackReturnAddresses)
    }
    
    public func catching(types: ExceptionTypes,
                         closure: @escaping () -> ()) async throws
    {

        var context = ExceptionContext(currentExceptionMask: types.exceptionMask,
                                       currentExceptionPort: 0,
                                       count: 0,
                                       masks: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       ports: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       behaviors: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                       flavors: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        
        ExceptionTLS.$completionHandler.withValue(self.exceptionHandler) {
            guard let me = MException() else {
                fatalError("MException init failed")
            }
            
            do {
                try me.prepareToCatch(with: &context)
                let port = context.currentExceptionPort
                listener = Task {
                    while Task.isCancelled == false {
                        do {
                            print("starting to listen")
                            try me.listen(onPort: port, timeout: 10)
                            print("listener done")
                            break
                        } catch let error as NSError where error.code == MACH_RCV_TIMED_OUT {
                            print("listener timeout")
                            continue
                        } catch let error as NSError {
                            print("listener failed")
                            throw error
                        }
                    }
                }
            } catch {
                let error = error as NSError
                print(error.localizedDescription)
            }
            
            operation = Task {
                let previousExclusivity = _swift_disableExclusivityChecking
                let previousReporting = _swift_reportFatalErrorsToDebugger
                _swift_disableExclusivityChecking = true
                _swift_reportFatalErrorsToDebugger = false
                defer {
                    _swift_reportFatalErrorsToDebugger = previousReporting
                    _swift_disableExclusivityChecking = previousExclusivity
                }
                
                defer {
                    print("DEFER")
                    listener?.cancel()
                }
                
                closure()
                print("DONE")
            }
        }
        
        let result = await listener?.result
        print("listener: \(await listener?.result)")
        print("operation: \(await operation?.result)")
        if let error = self.error, let exceptionError = ExceptionError(error) {
            throw exceptionError
        }
    }
}
