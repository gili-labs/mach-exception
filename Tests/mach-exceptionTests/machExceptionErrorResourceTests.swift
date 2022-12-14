//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// machExceptionErrorResourceTests.swift
// Created by Patrick Gili on 11/27/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class machExceptionErrorResourceTests: XCTestCase {

    func testMachExceptionResourceInfoCpu() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        var subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_CPU
        code.flavor = MachExceptionResourceInfo.CpuFlavor.monitor.rawValue
        code.cpuInterval = 1
        code.cpuLimit = 2
        subcode.cpuUtilization = 3
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.resource)
        XCTAssertEqual(info, .cpu(flavor: .monitor, interval: 1, limit: 2, utilization: 3))
    }
    
    func testMachExceptionResourceInfoCpuInvalidFlavor() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        var subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_CPU
        code.flavor = 0
        code.cpuInterval = 1
        code.cpuLimit = 2
        subcode.cpuUtilization = 3
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
    
    func testMachExceptionResourceInfoWakeups() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        var subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_WAKEUPS
        code.flavor = MachExceptionResourceInfo.WakeupsFlavor.monitor.rawValue
        code.wakeupsInterval = 1
        code.wakeupsPermitted = 2
        subcode.wakeupsObserved = 3
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.resource)
        XCTAssertEqual(info, .wakeups(flavor: .monitor, interval: 1, permitted: 2, wakeups: 3))
    }

    func testMachExceptionResourceInfoWakeupsInvalidFlavor() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        var subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_WAKEUPS
        code.flavor = 0
        code.cpuInterval = 1
        code.cpuLimit = 2
        subcode.cpuUtilization = 3
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
    
    func testMachExceptionResourceInfoMemory() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        let subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_MEMORY
        code.flavor = MachExceptionResourceInfo.MemoryFlavor.highWatermark.rawValue
        code.memoryHWMLimit = 1
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.resource)
        XCTAssertEqual(info, .memory(flavor: .highWatermark, highWatermark: 1))
    }

    func testMachExceptionResourceInfoMemoryInvalidFlavor() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        let subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_MEMORY
        code.flavor = 0
        code.memoryHWMLimit = 1
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }

    func testMachExceptionResourceInfoIO() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        var subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_IO
        code.flavor = MachExceptionResourceInfo.IOFlavor.physicalWrites.rawValue
        code.ioInterval = 1
        code.ioLimit = 2
        subcode.ioCount = 3
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.resource)
        XCTAssertEqual(info, .io(flavor: .physicalWrites, interval: 1, limit: 2, count: 3))
    }

    func testMachExceptionResourceInfoIOInvalidFlavor() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        var subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_IO
        code.flavor = 0
        code.ioInterval = 1
        code.ioLimit = 2
        subcode.ioCount = 3
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }

    func testMachExceptionResourceInfoThreads() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        let subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_THREADS
        code.flavor = MachExceptionResourceInfo.ThreadsFlavor.highWatermark.rawValue
        code.threadsCount = 1
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        let info = try XCTUnwrap(error.resource)
        XCTAssertEqual(info, .threads(flavor: .highWatermark, count: 1))
    }

    func testMachExceptionResourceInfoThreadsInvalidFlavor() throws {
        var code = MachExceptionResourceInfo.Code(value: 0)
        let subcode = MachExceptionResourceInfo.Subcode(value: 0)
        code.type = RESOURCE_TYPE_THREADS
        code.flavor = 0
        code.threadsCount = 1
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: subcode.value)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
    
    func testMachExceptionResourceInfoInvalidType() throws {
        var code = MachExceptionGuardInfo.Code(value: 0)
        code.type = 7
        let nsError = makeNSError(type: EXC_RESOURCE, code: code.value, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
    
    func testMachExceptionResourceInfoWrongType() throws {
        let nsError = makeNSError(type: EXC_BAD_ACCESS, code: nil, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
    
    func testMachExceptionResourceInfoNoCode() throws {
        let nsError = makeNSError(type: EXC_RESOURCE, code: nil, subcode: 3)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
    
    func testMachExceptionResourceInfoNoSubcode() throws {
        let nsError = makeNSError(type: EXC_RESOURCE, code: 1, subcode: nil)
        let error = try XCTUnwrap(MachExceptionError(nsError))
        XCTAssertNil(error.resource)
    }
}
