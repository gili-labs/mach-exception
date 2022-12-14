//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorBadAccessTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorBadAccessTests: XCTestCase {

#if arch(arm) || arch(arm64)
    func testMachExceptionBadAccessInfoVMFault() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(KERN_INVALID_ADDRESS),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .vmFault(kernResult: KERN_INVALID_ADDRESS))
    }
    
    func testMachExceptionBadAccessInfoDataAccessAlignmentFault() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(EXC_ARM_DA_ALIGN),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .dataAccessAlignment)
    }
    
    func testMachExceptionBadAccessInfoDataAccessDebugException() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(EXC_ARM_DA_DEBUG),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .dataAccessDebug)
    }
    
    func testMachExceptionBadAccessInfoStackPointerAlignmentFault() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(EXC_ARM_SP_ALIGN),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .stackPointerAlignment)
    }
    
    func testMachExceptionBadAccessInfoSWPInstructionDataAbort() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(EXC_ARM_SWP),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .swpInstruction)
    }
    
    func testMachExceptionBadAccessInfoPointerAuthenticationFailure() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(EXC_ARM_PAC_FAIL),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .pointerAuthenticationFailure)
    }
    
#elseif arch(i386) || arch(x86_64)
    func testMachExceptionBadAccessInfoFPUOverranSegmentFaultOnRead() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(VM_PROT_READ | VM_PROT_EXECUTE),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .fpuSegmentFault)
    }
    
    func testMachExceptionBadAccessInfoGeneralProtectionFault() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(EXC_I386_GPFLT),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.badAccess)
        XCTAssertEqual(info.address, 0x0)
        XCTAssertEqual(info.code, .generalProtectionFault)
     }
    
#endif
    func testMachExceptionBadAccessInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_INSTRUCTION, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badAccess)
    }
    
    func testMachExceptionBadAccessInfoWrongCode() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS,
                                  code: mach_exception_data_type_t(0x0000_0000_7fff_ffff),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badAccess)
    }
    
    func testMachExceptionBadAccessInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badAccess)
    }
    
    func testMachExceptionBadAccessInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.badAccess)
    }
}
