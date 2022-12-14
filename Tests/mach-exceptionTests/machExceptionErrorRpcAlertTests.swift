//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorRpcAlertTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorRpcAlertTests: XCTestCase {

    func testMachExceptionRpcAlertInfo() throws {
        let nsError = makeNSError(type: EXC_RPC_ALERT,
                                  code: 0xff000001,
                                  subcode: 0x1)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.rpcAlert)
        XCTAssertEqual(info.code, 0xff000001)
        XCTAssertEqual(info.pid, 0x1)
    }
    
    func testMachExceptionRpcAlertInfoFailed() throws {
        let nsError = makeNSError(type: EXC_RPC_ALERT, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.rpcAlert)
    }
        
    func testMachExceptionRpcAlertInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.rpcAlert)
    }
    
    func testMachExceptionRpcAlertInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_RPC_ALERT, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.rpcAlert)
    }
    
    func testMachExceptionRpcAlertInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_RPC_ALERT, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.rpcAlert)
    }
}
