//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorCorpseNotifyTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorCorpseNotifyTests: XCTestCase {

    func testMachExceptionCorpseNotifyInfoCrash() throws {
        var subcode = MachExceptionCorpseNotifyInfo.Subcode(value: 0)
        subcode.namespace = OSReasonNamespace.invalid.rawValue
        subcode.reason = 2
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(EXC_CRASH),
                                  subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.corpseNotify)
        XCTAssertEqual(info, .crash(namespace: .invalid, reason: 0x2))
    }
    
    func testMachExceptionCorpseNotifyInfoCrashInvalidNamespace() throws {
        var subcode = MachExceptionCorpseNotifyInfo.Subcode(value: 0)
        subcode.namespace = 0xff
        subcode.reason = 2
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(EXC_CRASH),
                                  subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }
    
    func testMachExceptionCorpseNotifyInfoResource() throws {
        var resourceCode = MachExceptionResourceInfo.Code(value: 0)
        resourceCode.type = RESOURCE_TYPE_CPU
        resourceCode.flavor = MachExceptionResourceInfo.CpuFlavor.monitor.rawValue
        resourceCode.cpuInterval = 1
        resourceCode.cpuLimit = 2
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(EXC_RESOURCE),
                                  subcode: resourceCode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.corpseNotify)
        XCTAssertEqual(info, .resource(info: .cpu(flavor: .monitor, interval: 1, limit: 2, utilization: 0)))
    }
    
    func testMachExceptionCorpseNotifyInfoResourceInvalid() throws {
        var resourceCode = MachExceptionResourceInfo.Code(value: 0)
        resourceCode.type = 7
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(EXC_RESOURCE),
                                  subcode: resourceCode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }
    
    func testMachExceptionCorpseNotifyInfoGuard() throws {
        var guardCode = MachExceptionGuardInfo.Code(value: 0)
        guardCode.type = GUARD_TYPE_MACH_PORT
        guardCode.portName = 1
        guardCode.reason = 2
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(EXC_GUARD),
                                  subcode: guardCode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.corpseNotify)
        XCTAssertEqual(info, .guard(info: .machPort(port: 1, reason: kGUARD_EXC_MOD_REFS, guardId: 0)))
    }
    
    func testMachExceptionCorpseNotifyInfoGuardInvalid() throws {
        var guardCode = MachExceptionGuardInfo.Code(value: 0)
        guardCode.type = 7
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(EXC_GUARD),
                                  subcode: guardCode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }

    func testMachExceptionCorpseNotifyInfoInvalidCode() throws {
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY,
                                  code: mach_exception_data_type_t(0),
                                  subcode: 0)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }
    
    func testMachExceptionCorpseNotifyInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }
    
    func testMachExceptionCorpseNotifyInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }
    
    func testMachExceptionCorpseNotifyInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_CORPSE_NOTIFY, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.corpseNotify)
    }
}
