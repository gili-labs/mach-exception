//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorCrashTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorCrashTests: XCTestCase {

    func testMachExceptionCrashInfoCpu() throws {
        var code = MachExceptionCrashInfo.Code(value: 0)
        code.originalException = EXC_GUARD
        code.originalCode = 1
        code.signalValue = 2
        let nsError = makeNSError(type: EXC_CRASH, code: code.value, subcode: 0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.crash)
        XCTAssertEqual(info.originalException, EXC_GUARD)
        XCTAssertEqual(info.originalCode, 0x1)
        XCTAssertEqual(info.signalValue, 0x2)
    }
    
    func testMachExceptionCrashInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.crash)
    }
    
    func testMachExceptionCrashInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_CRASH, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.crash)
    }
    
    func testMachExceptionCrashInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_CRASH, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.crash)
    }
}
