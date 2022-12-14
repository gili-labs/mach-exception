//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorMachSysCallTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorMachSysCallTests: XCTestCase {

    func testMachExceptionMachSysCallInfoInfo() throws {
        let nsError = makeNSError(type: EXC_MACH_SYSCALL,
                                  code: 0x1,
                                  subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertEqual(error.machSyscall, 0x1)
    }
    
    func testMachExceptionMachSysCallInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.machSyscall)
    }
    
    func testMachExceptionMachSysCallInfoFailed() throws {
        let nsError = makeNSError(type: EXC_MACH_SYSCALL, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.machSyscall)
    }
}
