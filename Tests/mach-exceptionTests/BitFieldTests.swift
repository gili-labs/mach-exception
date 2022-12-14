//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// BitFieldTests.swift
// Created by Patrick Gili on 11/28/22.
//

import XCTest

@testable import mach_exception

final class BitFieldsTests: XCTestCase {
    
    func testBitFields() throws {
        var example = Nybbles(value: 0)
        XCTAssertEqual(example.value, 0)

        example.value = 0
        example.nybble1 = 0xf
        XCTAssertEqual(example.value, 0xf)
        XCTAssertEqual(example.nybble1, 0xf)
        
        example.value = 0
        example.nybble2 = 0xf
        XCTAssertEqual(example.value, 0xf0)
        XCTAssertEqual(example.nybble2, 0xf)

        example.value = 0
        example.nybble3 = 0xf
        XCTAssertEqual(example.value, 0xf00)
        XCTAssertEqual(example.nybble3, 0xf)

        example.value = 0
        example.nybble4 = 0xf
        XCTAssertEqual(example.value, 0xf000)
        XCTAssertEqual(example.nybble4, 0xf)
        
        XCTAssertEqual(example.nybble5, 0)
        
        example.value = 0
        example.nybble5 = 0xf
        XCTAssertEqual(example.value, 0)
    }
}

struct Nybbles: BitFields {

    var value: UInt16
    
    static var fields = Fields {
        Field("nybble1", 0, 3)
        Field("nybble2", 4, 7)
        Field("nybble3", 8, 11)
        Field("nybble4", 12, 15)
    }
}
