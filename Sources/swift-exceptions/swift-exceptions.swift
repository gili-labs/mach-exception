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
}

class Exception<OperationResult> {

    internal let machException: MachException
    internal let listenerTimeout: mach_msg_timeout_t
    internal var continuation: UnsafeContinuation<OperationResult, Error>?
     
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
     
    internal enum ExceptionChildTask<T> {
        case listener(())
        case operation(T)
    }

    public func withCatching(operation: @escaping () -> OperationResult) async throws -> OperationResult
    {
        return try await ExceptionTLS.$completionHandler.withValue(self.onFailure) {
            return try await withThrowingTaskGroup(of: ExceptionChildTask<OperationResult>.self) { group in
                var operationResult: OperationResult?
                
                group.addTask { [self] in
                    return .listener(try listen(withTimeout: listenerTimeout))
                }
                
                group.addTask { [self] in
                    try await .operation(perform(operation: operation))
                }
                
                for try await task in group {
                    switch task {
                    case .listener:
                        group.cancelAll()
                        
                    case .operation(let result):
                        group.cancelAll()
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
    
    internal func perform(operation: @escaping () -> OperationResult) async throws -> OperationResult {
        return try await withUnsafeThrowingContinuation { continuation in
            self.continuation = continuation
            defer {
                self.continuation = nil
            }
            let result = operation()
            print("OPERATION DONE")
            onSuccess(result)
        }
    }
    
    internal func onSuccess(_ result: OperationResult) {
        continuation?.resume(returning: result)
    }
    
    internal func onFailure(_ error: Error?) {
        print("GOT HERE, GOT HERE, GOT HERE!!!")
        guard let continuation = self.continuation, let error = error else {
            fatalError("BIG PROBLEM")
        }
        print(error as NSError)
        continuation.resume(throwing: error)
    }
}

public class OldException2 {

    internal var continuation: UnsafeContinuation<(), Error>?

    public func exceptionHandler(_ error: Error?) -> Void {
        print("GOT HERE, GOT HERE, GOT HERE!!!")
        guard let continuation = self.continuation, let error = error else {
            fatalError("BIG PROBLEM")
        }
        print(error as NSError)
        continuation.resume(throwing: error)
    }
    
    var listener: Task<(), Error>?
    var operation: Task<(), Error>?

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
        
        await ExceptionTLS.$completionHandler.withValue(self.exceptionHandler) {
            guard let me = MException() else {
                fatalError("MException init failed")
            }
            do {
                try me.prepareToCatch(with: &context)
                //try me.catchException(with: &context)
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
                
                return try await withUnsafeThrowingContinuation { continuation in
                    self.continuation = continuation
                    defer {
                        self.continuation = nil
                        listener?.cancel()
                    }
                    closure()
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
