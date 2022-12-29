//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach_exception_helper_tests.swift
// Created by Patrick Gili on 12/17/22.
//

import Foundation
import Darwin
import XCTest

import mach_exception
import mach_exception_helper

@testable import mach_exception

final class mach_exception_helper_tests: XCTestCase {
    
    func testCatchMachExceptionRaise() throws {
        var codes: [Int64] = []
        let result = catch_mach_exception_raise(0, 0, 0, 0, &codes, 0)
        XCTAssertEqual(result, KERN_NOT_SUPPORTED)
    }
    
    func testCatchMachExceptionRaiseState() throws {
        var codes: [Int64] = []
        var flavor: Int32 = 0
        var oldState: [UInt32] = []
        var newState: [UInt32] = []
        var newStateCount: mach_msg_type_number_t = 0
        let result = catch_mach_exception_raise_state(0, 0, &codes, 0, &flavor, &oldState, 0, &newState, &newStateCount)
        XCTAssertEqual(result, KERN_NOT_SUPPORTED)
    }
    
    func testMachExceptionHelperCreate() throws {
        let dependencies = TestableDependencies()
        XCTAssertNoThrow(try MachExceptionHelper(mask: exception_mask_t(EXC_MASK_BAD_ACCESS), dependencies: dependencies))
    }
    
    func testMachExceptionHelperSuperInitFailure() throws {
        let dependencies = TestableDependencies()
        dependencies.failureOptions = [.superInitFailure]
        XCTAssertThrowsError(try MachExceptionHelper(mask: exception_mask_t(EXC_MASK_BAD_ACCESS), dependencies: dependencies))
    }
    
    func testMachExceptionHelperPortAllocateFailure() throws {
        let dependencies = TestableDependencies()
        dependencies.failureOptions = [.portAllocateFailure]
        XCTAssertThrowsError(try MachExceptionHelper(mask: exception_mask_t(EXC_MASK_BAD_ACCESS), dependencies: dependencies))
    }
    
    func testMachExceptionHelperPortInsertRightFailure() throws {
        let dependencies = TestableDependencies()
        dependencies.failureOptions = [.portInsertRightFailure]
        XCTAssertThrowsError(try MachExceptionHelper(mask: exception_mask_t(EXC_MASK_BAD_ACCESS), dependencies: dependencies))
    }
    
    func testMachExceptionHelperThreadSwapExceptionPortsFailure() throws {
        let dependencies = TestableDependencies()
        dependencies.failureOptions = [.threadSwapExceptionPortsFailure]
        XCTAssertThrowsError(try MachExceptionHelper(mask: exception_mask_t(EXC_MASK_BAD_ACCESS), dependencies: dependencies))
    }
}

struct TestableDependenciesOptions: OptionSet {
    let rawValue: Int
    
    static let superInitFailure = TestableDependenciesOptions(rawValue: 1 << 0)
    static let portAllocateFailure = TestableDependenciesOptions(rawValue: 1 << 1)
    static let portInsertRightFailure = TestableDependenciesOptions(rawValue: 1 << 2)
    static let threadSwapExceptionPortsFailure = TestableDependenciesOptions(rawValue: 1 << 3)
}

class TestableDependencies: MachExceptionHelperDependencies {
    
    var failureOptions: TestableDependenciesOptions = []
    
    func super_init_fail() -> Bool {
        return failureOptions.contains(.superInitFailure)
    }
    
    func port_allocate(_ space: ipc_space_t,
                       right: mach_port_right_t,
                       name: UnsafeMutablePointer<mach_port_name_t>) -> kern_return_t
    {
        if failureOptions.contains(.portAllocateFailure) {
            return KERN_RESOURCE_SHORTAGE
        }
        return mach_port_allocate(space, right, name)
    }
    
    func port_insert_right(_ space: ipc_space_t,
                           name: mach_port_name_t,
                           port poly: mach_port_t,
                           polyPoly: mach_msg_type_name_t) -> kern_return_t
    {
        if failureOptions.contains(.portInsertRightFailure) {
            return KERN_RESOURCE_SHORTAGE
        }
        return mach_port_insert_right(space, name, poly, polyPoly)
    }
    
    func swap_exception_ports(_ thread: thread_t,
                              exception_mask: exception_mask_t,
                              new_port: mach_port_t,
                              new_behavior: exception_behavior_t,
                              new_flavor: thread_state_flavor_t,
                              masks: exception_mask_array_t,
                              countCnt CountCnt: UnsafeMutablePointer<mach_msg_type_number_t>,
                              ports: exception_port_array_t,
                              behaviors: exception_behavior_array_t,
                              flavors: thread_state_flavor_array_t) -> kern_return_t
    {
        print(failureOptions)
        if failureOptions.contains(.threadSwapExceptionPortsFailure) {
            return KERN_FAILURE
        }
        
        return thread_swap_exception_ports(thread,
                                           exception_mask,
                                           new_port,
                                           new_behavior,
                                           new_flavor,
                                           masks,
                                           CountCnt,
                                           ports,
                                           behaviors,
                                           flavors)
    }
}
