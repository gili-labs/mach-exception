//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach-exceptionsTest.swift
// Created by Patrick Gili on 5/17/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

class mach_exceptions: XCTestCase {

    func testWithUnsafeMachException() throws {
#if arch(arm) || arch(arm64)
        let exceptionType: MachExceptionTypes = [.breakpoint]
#elseif arch(i386) || arch(x86_64)
        let exceptionType: MachExceptionTypes = [.badInstruction]
#endif
        var caughtError: Error?
        XCTAssertThrowsError(
            try withUnsafeMachException(types: exceptionType)
        {
            fatalError("Testing fatal error")
        }
        ) { error in
            caughtError = error
        }
        let machExceptionError: MachExceptionError = try XCTUnwrap(caughtError as? MachExceptionError)
#if arch(arm) || arch(arm64)
        XCTAssertEqual(machExceptionError.type, .breakpoint)
#elseif arch(i386) || arch(x86_64)
        XCTAssertEqual(machExceptionError.type, .badAccess)
#endif
    }
    
    func testWithUnsafeMachExceptionWithNoException() throws {
#if arch(arm) || arch(arm64)
        let exceptionType: MachExceptionTypes = [.breakpoint]
#elseif arch(i386) || arch(x86_64)
        let exceptionType: MachExceptionTypes = [.badInstruction]
#endif
        XCTAssertNoThrow(
            try withUnsafeMachException(types: exceptionType)
            {
                sleep(1)
            })
    }
    
    func testWithUnsafeMachExceptionWithFinallyBlock() throws {
#if arch(arm) || arch(arm64)
        let exceptionType: MachExceptionTypes = [.breakpoint]
#elseif arch(i386) || arch(x86_64)
        let exceptionType: MachExceptionTypes = [.badInstruction]
#endif
        var finallyBlockWasExecuted = false
        XCTAssertNoThrow(
            try withUnsafeMachException(types: exceptionType)
            {
                sleep(1)
            } finally: {
                finallyBlockWasExecuted = true
            })
        XCTAssert(finallyBlockWasExecuted)
    }
}
