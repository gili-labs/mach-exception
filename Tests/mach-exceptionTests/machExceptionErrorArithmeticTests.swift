//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorArithmeticTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorArithmeticTests: XCTestCase {

#if arch(arm) || arch(arm64)
    func testMachExceptionArithmeticInfoUnderflow() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_UF),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .underflow)
        XCTAssertEqual(info.instruction, 0x0)
    }

    func testMachExceptionArithmeticInfoOverflow() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_OF),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .overflow)
        XCTAssertEqual(info.instruction, 0x0)
    }

    func testMachExceptionArithmeticInfoInvalidOperation() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_IO),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .invalidOperation)
        XCTAssertEqual(info.instruction, 0x0)
    }

    func testMachExceptionArithmeticInfoDivideError() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_DZ),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .divideError)
        XCTAssertEqual(info.instruction, 0x0)
    }

    func testMachExceptionArithmeticInfoDenormalInput() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_ID),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .denormalInput)
        XCTAssertEqual(info.instruction, 0x0)
    }

    func testMachExceptionArithmeticInfoInexactResult() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_IX),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .inexactResult)
        XCTAssertEqual(info.instruction, 0x0)
    }

    func testMachExceptionArithmeticInfoUndefined() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_ARM_FP_UNDEFINED),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .undefined)
        XCTAssertEqual(info.instruction, 0x0)
    }
    
#elseif arch(i386) || arch(x86_64)
    func testMachExceptionArithmeticInfoDivideError() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_I386_DIV),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .divideError)
        XCTAssertEqual(info.csr, 0x0)
    }
    
    func testMachExceptionArithmeticInfoOverflow() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_I386_INTO),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .overflow)
        XCTAssertEqual(info.csr, 0x0)
    }
    
    func testMachExceptionArithmeticInfoNoFPU() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_I386_NOEXT),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .noFPU)
        XCTAssertEqual(info.csr, 0x0)
    }
    
    func testMachExceptionArithmeticInfoFloatingPointError() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_I386_EXTERR),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .floatingPointError)
        XCTAssertEqual(info.csr, 0x0)
    }
    
    func testMachExceptionArithmeticInfoSIMDOperationError() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(EXC_I386_SSEEXTERR),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.arithmetic)
        XCTAssertEqual(info.code, .simdOperationError)
        XCTAssertEqual(info.csr, 0x0)
    }
    
#endif
    func testMachExceptionArithmeticInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.arithmetic)
    }
    
    func testMachExceptionArithmeticInfoWrongCode() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC,
                                  code: mach_exception_data_type_t(0x0000_0000_7fff_ffff),
                                  subcode: 0x0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.arithmetic)
    }

    func testMachExceptionArithmeticInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.arithmetic)
    }
    
    func testMachExceptionArithmeticInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_ARITHMETIC, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.arithmetic)
    }
}
