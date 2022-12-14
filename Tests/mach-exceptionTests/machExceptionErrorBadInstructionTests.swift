//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorBadInstructionTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorBadInstructionTests: XCTestCase {

#if arch(arm) || arch(arm64)
    func testMachExceptionBadInstructionInfoUndefined() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(EXC_ARM_UNDEFINED),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badInstruction)
        XCTAssertEqual(info.instruction, 0x0)
        XCTAssertEqual(info.code, .undefined)
    }
    
#elseif arch(i386) || arch(x86_64)
    func testMachExceptionBadInstructionInfoInvalidTSSFault() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(EXC_I386_INVTSSFLT),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badInstruction)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .invalidTSS)
    }
    
    func testMachExceptionBadInstructionInfoSegmentNotPresentFault() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(EXC_I386_SEGNPFLT),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badInstruction)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .segmentNotPresent)
    }
    
    func testMachExceptionBadInstructionInfoStackFault() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(EXC_I386_STKFLT),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badInstruction)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .stackFault)
    }
    
    func testMachExceptionBadInstructionInfoInvalidOpcodeFault() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(EXC_I386_INVOP),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badInstruction)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .invalidOpcode)
    }
    
    func testMachExceptionBadInstructionInfoPageFault() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(KERN_PROTECTION_FAILURE),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badInstruction)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .pageFault(kernResult: KERN_PROTECTION_FAILURE))
    }
    
#endif
    func testMachExceptionBadInstructionInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badInstruction)
    }
    
    func testMachExceptionBadInstructionInfoWrongCode() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION,
                                  code: mach_exception_data_type_t(0x0000_0000_7fff_ffff),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badInstruction)
    }

    func testMachExceptionBadInstructionInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badInstruction)
    }
    
    func testMachExceptionBadInstructionInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badInstruction)
    }
}
