//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// BitField.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

public struct Field {
    let name: String
    let lsb: Int
    let msb: Int
    
    init(_ name: String, _ lsb: Int, _ msb: Int) {
        self.name = name
        self.lsb = lsb
        self.msb = msb
    }
}

public struct Fields {
    
    internal var store: [String : (lsb: Int, msb: Int)] = [:]
    
    init(@BitFieldsBuilder fields: () -> [String : (lsb: Int, msb: Int)]) {
        self.store = fields()
    }
}

@dynamicMemberLookup
public protocol BitFields {
    
    associatedtype Value: FixedWidthInteger
    
    var value: Value { get set }
    
    static var fields: Fields { get }
    
    subscript<U: FixedWidthInteger>(dynamicMember member: String) -> U { get set }
}

extension BitFields {
    
    public subscript<U: FixedWidthInteger>(dynamicMember member: String) -> U {
        
        get {
            guard let field = Self.fields.store[member] else { return 0 }
            let width = field.msb - field.lsb + 1
            let mask: Value = 1 << width &- 1
            return U(truncatingIfNeeded: value >> field.lsb & mask)
        }
        
        set {
            guard let field = Self.fields.store[member] else { return }
            let width = field.msb - field.lsb + 1
            let mask: Value = 1 << width &- 1
            value &= ~(mask << field.lsb)
            value |= (Value(truncatingIfNeeded: newValue) & mask) << field.lsb
        }
    }
}

@resultBuilder
enum BitFieldsBuilder {
    
    static func buildBlock(_ components: Field...) -> [String : (lsb: Int, msb: Int)] {
        let components: [Field] = components
        var result = [String : (lsb: Int, msb: Int)]()
        for component in components {
            result[component.name] = (component.lsb, component.msb)
        }
        return result
    }
}
