//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorBreakpointTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorBreakpointTests: XCTestCase {

#if arch(arm) || arch(arm64)
    func testMachExceptionBreakpointInfoBreakpoint() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_ARM_BREAKPOINT),
                                  subcode: 0x1)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.codes, .breakpoint(address: 0x01))
    }
    
    func testMachExceptionBreakpointInfoGDBBreakpoint1() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_ARM_BREAKPOINT),
                                  subcode: mach_exception_data_type_t(ARM_GDB_INSTR1))
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.codes, .gdbBreakpoint(instruction: ARM_GDB_INSTR1))
    }
    
    func testMachExceptionBreakpointInfoGDBBreakpoint2() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_ARM_BREAKPOINT),
                                  subcode: mach_exception_data_type_t(ARM_GDB_INSTR2))
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.codes, .gdbBreakpoint(instruction: ARM_GDB_INSTR2))
    }
    
    func testMachExceptionBreakpointInfoWatchpoint() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_ARM_DA_DEBUG),
                                  subcode: 0x01)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.codes, .watchpoint(address: 0x01))
    }
    
    func testMachExceptionBreakpointInfoSingleStep() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(1),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.codes, .singleStep)
    }
    
#elseif arch(i386) || arch(x86_64)
    func testMachExceptionBreakpointInfoOutOfBounds() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_I386_BOUND),
                                  subcode: 0x1)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.code, .outOfBounds)
        XCTAssertEqual(info.subcode, 0x1)
    }

    func testMachExceptionBreakpointInfoDebug() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_I386_SGL),
                                  subcode: 0x1)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.code, .debug)
        XCTAssertEqual(info.subcode, 0x1)
    }

    func testMachExceptionBreakpointInfoBreakpoint() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(EXC_I386_BPT),
                                  subcode: 0x1)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.breakpoint)
        XCTAssertEqual(info.code, .breakpoint)
        XCTAssertEqual(info.subcode, 0x1)
    }

#endif
    func testMachExceptionBreakpointInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.breakpoint)
    }
    
    func testMachExceptionBreakpointInfoWrongCode() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT,
                                  code: mach_exception_data_type_t(0x0000_0000_7fff_ffff),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.breakpoint)
    }

    func testMachExceptionBreakpointInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.breakpoint)
    }
    
    func testMachExceptionBreakpointInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_BREAKPOINT, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.breakpoint)
    }
}
