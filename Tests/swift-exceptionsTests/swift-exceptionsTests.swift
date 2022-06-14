//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// swift-exceptionsTests.swift
// Created by Patrick Gili on 5/17/22.
//

import Foundation
import Darwin
import XCTest

//#if SWIFT_PACKAGE
import mach_exceptions
//#endif

@testable import swift_exceptions

class swift_exceptions: XCTestCase {

    func testIt() throws {
        let exception = MachException()
        XCTAssertNoThrow(try exception.prepareToListen(forException: exception_mask_t(EXC_MASK_BREAKPOINT)))
        
    }
    
    func testExceptionTypes() throws {
        XCTAssertEqual(ExceptionTypes.badAccess.rawValue, EXC_MASK_BAD_ACCESS)
        XCTAssertEqual(ExceptionTypes.badInstruction.rawValue, EXC_MASK_BAD_INSTRUCTION)
        XCTAssertEqual(ExceptionTypes.arithmetic.rawValue, EXC_MASK_ARITHMETIC)
        XCTAssertEqual(ExceptionTypes.emulation.rawValue, EXC_MASK_EMULATION)
        XCTAssertEqual(ExceptionTypes.software.rawValue, EXC_MASK_SOFTWARE)
        XCTAssertEqual(ExceptionTypes.breakpoint.rawValue, EXC_MASK_BREAKPOINT)
        XCTAssertEqual(ExceptionTypes.syscall.rawValue, EXC_MASK_SYSCALL)
        XCTAssertEqual(ExceptionTypes.machSyscall.rawValue, EXC_MASK_MACH_SYSCALL)
        XCTAssertEqual(ExceptionTypes.rpcAlert.rawValue, EXC_MASK_RPC_ALERT)
        XCTAssertEqual(ExceptionTypes.crash.rawValue, EXC_MASK_CRASH)
        XCTAssertEqual(ExceptionTypes.resource.rawValue, EXC_MASK_RESOURCE)
        XCTAssertEqual(ExceptionTypes.guard.rawValue, EXC_MASK_GUARD)
        XCTAssertEqual(ExceptionTypes.corpseNotify.rawValue, EXC_MASK_CORPSE_NOTIFY)
    }
    
    func testCatchMachException() throws {
        let thread = Thread {
            let exception = Exception()
            exception.catching(types: .breakpoint) { (type, code, subcode) in
                print("EXCEPTION CAUGHT")
                print("  type: \(type)")
                print("  code: \(code)")
                print("  subcode: \(subcode)")
            } closure: {
                print("WHO CARES")
                
                //fatalError()
            }
        }
        thread.start()
        sleep(2)
    }            
}
