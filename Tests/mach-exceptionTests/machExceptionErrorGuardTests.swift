//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorGuardTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorGuardTests: XCTestCase {

    func testMachExceptionGuardInfoNone() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_NONE
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.guard)
        XCTAssertEqual(info, .none)
    }
    
    func testMachExceptionGuardInfoMachPort() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_MACH_PORT
        code.portName = 1
        code.reason = 2
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.guard)
        XCTAssertEqual(info, .machPort(port: 1, reason: mach_port_guard_exception_codes(rawValue: 2), guardId: 3))
    }
    
    func testMachExceptionGuardInfoFileDescriptor() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_FD
        code.fileDescriptor = 1
        code.flavor = 2
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.guard)
        XCTAssertEqual(info, .fileDescriptor(fileDescriptor: 1, flavor: .dup, guardId: 3))
    }

    
    func testMachExceptionGuardInfoUser() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_USER
        code.namespace = 1
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.guard)
        XCTAssertEqual(info, .user(namespace: .jetsam, reason: 3))
    }

    func testMachExceptionGuardInfoUserInvalidNamespace() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_USER
        code.namespace = 255
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.guard)
    }

    func testMachExceptionGuardInfoVNode() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_VN
        code.pid = 1
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.guard)
        XCTAssertEqual(info, .vNode(pid: 1, guardId: [.renameTo, .renameFrom]))
    }
    
    func testMachExceptionGuardInfoVirtualMemory() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = GUARD_TYPE_VIRT_MEMORY
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.guard)
        XCTAssertEqual(info, .virtualMemory(offset: 3))
    }
    
    func testMachExceptionGuardInfoInvalidType() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = 7
        let nsError = makeNSError(type: EXC_GUARD, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.guard)
    }
    
    func testMachExceptionGuardInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_RESOURCE, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.guard)
    }
    
    func testMachExceptionResourceInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_GUARD, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.guard)
    }
    
    func testMachExceptionResourceInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_GUARD, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.guard)
    }
}
