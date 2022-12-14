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
    
    func testMachExceptionErrorFromNSError() throws {
        assertMachExceptionError(EXC_BAD_ACCESS, 1, 2, .init(.badAccess, 1, 2))
        assertMachExceptionError(EXC_BAD_INSTRUCTION, 1, 2, .init(.badInstruction, 1, 2))
        assertMachExceptionError(EXC_ARITHMETIC, 1, 2, .init(.arithmetic, 1, 2))
        assertMachExceptionError(EXC_EMULATION, 1, 2, .init(.emulation, 1, 2))
        assertMachExceptionError(EXC_SOFTWARE, 1, 2, .init(.software, 1, 2))
        assertMachExceptionError(EXC_BREAKPOINT, 1, 2, .init(.breakpoint, 1, 2))
        assertMachExceptionError(EXC_SYSCALL, 1, 2, .init(.syscall, 1, 2))
        assertMachExceptionError(EXC_MACH_SYSCALL, 1, 2, .init(.machSyscall, 1, 2))
        assertMachExceptionError(EXC_RPC_ALERT, 1, 2, .init(.rpcAlert, 1, 2))
        assertMachExceptionError(EXC_CRASH, 1, 2, .init(.crash, 1, 2))
        assertMachExceptionError(EXC_RESOURCE, 1, 2, .init(.resource, 1, 2))
        assertMachExceptionError(EXC_GUARD, 1, 2, .init(.guard, 1, 2))
        assertMachExceptionError(EXC_CORPSE_NOTIFY, 1, 2, .init(.corpseNotify, 1, 2))
        assertMachExceptionError(EXC_BAD_ACCESS, nil, 2, .init(.badAccess, nil, 2))
        assertMachExceptionError(EXC_BAD_ACCESS, 1, nil, .init(.badAccess, 1, nil))
    }
    
    func assertMachExceptionError(_ type: Int32,
                                  _ code: mach_exception_data_type_t?,
                                  _ subcode: mach_exception_data_type_t?,
                                  _ expected: MachExceptionError,
                                  file: StaticString = #filePath, line: UInt = #line)
    {
        var userInfo: [String : Any] = [:]
        if let code = code {
            userInfo[MachExceptionCode] = code
        }
        if let subcode = subcode {
            userInfo[MachExceptionSubcode] = subcode
        }
        let error = NSError(domain: MachExceptionErrorDomain,
                            code: Int(type),
                            userInfo: userInfo)
        
        let machExceptionError = MachExceptionError(error)
        XCTAssertEqual(machExceptionError, expected, file: file, line: line)
    }
    
    func testWithUnsafeMachException() throws {
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
