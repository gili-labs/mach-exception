//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorSysCallTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorSysCallTests: XCTestCase {

    func testMachExceptionSysCallInfoInfo() throws {
        let nsError = makeNSError(type: EXC_SYSCALL,
                                  code: 0x1,
                                  subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertEqual(error.syscall, 0x1)
    }
    
    func testMachExceptionSysCallInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.syscall)
    }
    
    func testMachExceptionSysCallInfoFailed() throws {
        let nsError = makeNSError(type: EXC_SYSCALL, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.syscall)
    }
}
