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
//    func assertMachExceptionError(_ type: Int32,
//                                  _ code: mach_exception_data_type_t?,
//                                  _ subcode: mach_exception_data_type_t?,
//                                  _ expected: MachExceptionError,
//                                  file: StaticString = #filePath, line: UInt = #line)
//    {
//        var userInfo: [String : Any] = [:]
//        if let code = code {
//            userInfo[MachExceptionCode] = code
//        }
//        if let subcode = subcode {
//            userInfo[MachExceptionSubcode] = subcode
//        }
//        let error = NSError(domain: MachExceptionErrorDomain,
//                            code: Int(type),
//                            userInfo: userInfo)
//
//        let machExceptionError = MachExceptionError(error)
//        XCTAssertEqual(machExceptionError, expected, file: file, line: line)
//    }
    
    func testWithUnsafeMachException2() throws {
        var caughtError: Error?
        do {
            try withUnsafeMachException(types: [.badInstruction, .breakpoint]) {
                fatalError("Testing fatal error")
            }
        } catch {
            print("exception error = \(error)")
        }
        XCTAssertThrowsError(try catchFatalError()) { error in
            caughtError = error
        }
        
        let machExceptionError: MachExceptionError = try XCTUnwrap(caughtError as? MachExceptionError)
#if arch(arm) || arch(arm64)
        XCTAssertEqual(machExceptionError.type, .breakpoint)
#elseif arch(i386) || arch(x86_64)
#endif
    }
    
    func catchFatalError() throws {
        try withUnsafeMachException(types: [.badInstruction, .breakpoint]) {
            fatalError("Testing fatal error")
        }
    }
}
