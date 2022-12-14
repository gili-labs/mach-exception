//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorCrash.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

/// A type describing the information conveyed by the codes associated with
/// a Mach crash exception.
public struct MachExceptionCrashInfo {
    
    /// The original exception that caused the crash.
    public let originalException: exception_type_t
    
    /// The code associated with the original exception that caused the crash.
    public let originalCode: mach_exception_data_type_t
    
    /// The signal value used by the crash reporter.
    public let signalValue: Int64
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let crashCode = code, let _ = subcode else { return nil }
        let code = Code(value: crashCode)
        self.originalException = code.originalException
        self.originalCode = code.originalCode
        self.signalValue = code.signalValue
    }
    
    // See proc_prepareexit() in darwin-xnu/bsd/kern/kern_exit.c.
    public struct Code: BitFields {
        
        public var value: mach_exception_data_type_t = 0
        
        public static var fields = Fields {
            Field("originalException", 20, 23)
            Field("originalCode", 0, 19)
            Field("signalValue", 24, 31)
        }
    }
}
