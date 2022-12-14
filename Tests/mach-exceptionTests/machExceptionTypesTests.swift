//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionTypesTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

class machExceptionTypes: XCTestCase {
    
    func testMachExceptionTypesCreate() throws {
        let types: MachExceptionTypes = [.badInstruction, .breakpoint]
        XCTAssertEqual(types.rawValue, EXC_MASK_BAD_INSTRUCTION | EXC_MASK_BREAKPOINT)
    }
    
    func testMachExceptionTypesRawValue() throws {
        XCTAssertEqual(MachExceptionTypes.badAccess.rawValue, EXC_MASK_BAD_ACCESS)
        XCTAssertEqual(MachExceptionTypes.badInstruction.rawValue, EXC_MASK_BAD_INSTRUCTION)
        XCTAssertEqual(MachExceptionTypes.arithmetic.rawValue, EXC_MASK_ARITHMETIC)
        XCTAssertEqual(MachExceptionTypes.emulation.rawValue, EXC_MASK_EMULATION)
        XCTAssertEqual(MachExceptionTypes.software.rawValue, EXC_MASK_SOFTWARE)
        XCTAssertEqual(MachExceptionTypes.breakpoint.rawValue, EXC_MASK_BREAKPOINT)
        XCTAssertEqual(MachExceptionTypes.syscall.rawValue, EXC_MASK_SYSCALL)
        XCTAssertEqual(MachExceptionTypes.machSyscall.rawValue, EXC_MASK_MACH_SYSCALL)
        XCTAssertEqual(MachExceptionTypes.rpcAlert.rawValue, EXC_MASK_RPC_ALERT)
        XCTAssertEqual(MachExceptionTypes.crash.rawValue, EXC_MASK_CRASH)
        XCTAssertEqual(MachExceptionTypes.resource.rawValue, EXC_MASK_RESOURCE)
        XCTAssertEqual(MachExceptionTypes.guard.rawValue, EXC_MASK_GUARD)
        XCTAssertEqual(MachExceptionTypes.corpseNotify.rawValue, EXC_MASK_CORPSE_NOTIFY)
    }
    
    func testMachExceptionTypesExceptionMask() throws {
        let types: MachExceptionTypes = [.badInstruction, .breakpoint]
        let expected = exception_mask_t(EXC_MASK_BAD_INSTRUCTION | EXC_MASK_BREAKPOINT)
        XCTAssertEqual(types.exceptionMask, expected)
    }
}

class machExceptionType: XCTestCase {
    
    func testMachExceptionTypeCreate() throws {
        XCTAssertEqual(MachExceptionType(rawValue: EXC_BAD_ACCESS), .badAccess)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_BAD_INSTRUCTION), .badInstruction)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_ARITHMETIC), .arithmetic)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_EMULATION), .emulation)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_SOFTWARE), .software)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_BREAKPOINT), .breakpoint)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_SYSCALL), .syscall)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_MACH_SYSCALL), .machSyscall)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_RPC_ALERT), .rpcAlert)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_CRASH), .crash)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_RESOURCE), .resource)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_GUARD), .guard)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_CORPSE_NOTIFY), .corpseNotify)
        XCTAssertEqual(MachExceptionType(rawValue: EXC_TYPES_COUNT), nil)
    }
    
    func testMachExceptionTypeRawValue() throws {
        XCTAssertEqual(MachExceptionType.badAccess.rawValue, Int32(EXC_BAD_ACCESS))
        XCTAssertEqual(MachExceptionType.badInstruction.rawValue, Int32(EXC_BAD_INSTRUCTION))
        XCTAssertEqual(MachExceptionType.arithmetic.rawValue, Int32(EXC_ARITHMETIC))
        XCTAssertEqual(MachExceptionType.emulation.rawValue, Int32(EXC_EMULATION))
        XCTAssertEqual(MachExceptionType.software.rawValue, Int32(EXC_SOFTWARE))
        XCTAssertEqual(MachExceptionType.breakpoint.rawValue, Int32(EXC_BREAKPOINT))
        XCTAssertEqual(MachExceptionType.syscall.rawValue, Int32(EXC_SYSCALL))
        XCTAssertEqual(MachExceptionType.machSyscall.rawValue, Int32(EXC_MACH_SYSCALL))
        XCTAssertEqual(MachExceptionType.rpcAlert.rawValue, Int32(EXC_RPC_ALERT))
        XCTAssertEqual(MachExceptionType.crash.rawValue, Int32(EXC_CRASH))
        XCTAssertEqual(MachExceptionType.resource.rawValue, Int32(EXC_RESOURCE))
        XCTAssertEqual(MachExceptionType.guard.rawValue, Int32(EXC_GUARD))
        XCTAssertEqual(MachExceptionType.corpseNotify.rawValue, Int32(EXC_CORPSE_NOTIFY))
    }
}

