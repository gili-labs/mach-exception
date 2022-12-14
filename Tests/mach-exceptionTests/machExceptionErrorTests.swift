//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorTests: XCTestCase {

    func testMachExceptionErrorCreate() throws {
        let error = MachExceptionError(MachExceptionType.badAccess, nil, nil)
        XCTAssertEqual(error.type, MachExceptionType.badAccess)
        XCTAssertEqual(error.code, nil)
        XCTAssertEqual(error.subcode, nil)
    }
    
    func testMachExceptionErrorCreateFromNSError() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: 0x01, subcode: 0x02)
        let error = MachExceptionError(nsError)
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.type, MachExceptionType.badAccess)
        XCTAssertEqual(error?.code, 0x1)
        XCTAssertEqual(error?.subcode, 0x2)
    }
    
    func testMachExceptionErrorCreateFromNSErrorFailed() throws {
        let nsError = makeNSError(type: 0, code: nil, subcode: nil)
        let error = MachExceptionError(nsError)
        XCTAssertNil(error)
    }
}
