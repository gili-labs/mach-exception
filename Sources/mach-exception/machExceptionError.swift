//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionError.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation
import mach_exception_helper

/// An error describing a Mach exception.
public struct MachExceptionError: Error, Equatable {
    
    /// The type of Mach exception thrown.
    public let type: MachExceptionType
    
    /// The code associated with the Mach exception throw.
    public let code: mach_exception_data_type_t?
    
    /// The subcode associated with the Mach exception thrown.
    public let subcode: mach_exception_data_type_t?
    
    // Create a Mach exception error.
    //
    // - Note: only used for testing purposes.
    internal init(_ type: MachExceptionType,
                  _ code: Int64?,
                  _ subcode: Int64?)
    {
        self.type = type
        self.code = code
        self.subcode = subcode
    }
    
    // Create a Mach exception error from a NSError object. The NSError object's `code`
    // should indicate the Mach exception type. The NSError's `userdict` should contain
    // two entries for the Mach exception's code and subcode.
    internal init?(_ error: NSError) {
        guard let type = MachExceptionType(rawValue: Int32(error.code)) else {
            return nil
        }
        self.type = type
        
        if let value: Int64 = error[MachExceptionCode] {
            self.code = mach_exception_data_type_t(value)
        } else {
            self.code = nil
        }
        
        if let value: Int64 = error[MachExceptionSubcode] {
            self.subcode = mach_exception_data_type_t(value)
        } else {
            self.subcode = nil
        }
    }

    /// The information associated with a Mach bad access exception.
    public var badAccess: MachExceptionBadAccessInfo? {
        guard type == .badAccess else { return nil }
        return MachExceptionBadAccessInfo(code, subcode)
    }
    
    /// The information associated with a Mach bad instruction exception.
    public var badInstruction: MachExceptionBadInstructionInfo? {
        guard type == .badInstruction else { return nil }
        return MachExceptionBadInstructionInfo(code, subcode)
    }
    
    /// The information associated with a Mach arithmetic exception.
    public var arithmetic: MachExceptionArithmeticInfo? {
        guard type == .arithmetic else { return nil }
        return MachExceptionArithmeticInfo(code, subcode)
    }
    
    /// The information associated with a Mach breakpoint exception.
    public var breakpoint: MachExceptionBreakpointInfo? {
        guard type == .breakpoint else { return nil }
        return MachExceptionBreakpointInfo(code, subcode)
    }
    
    /// The information associated with a Mach syscall exception.
    public var syscall: UInt64? {
        guard type == .syscall, let code = code else { return nil }
        return UInt64(code)
    }
    
    /// The information associated with a Mach syscall exception.
    public var machSyscall: UInt64? {
        guard type == .machSyscall, let code = code else { return nil }
        return UInt64(code)
    }
    
    /// The information associated with a Mach RPC alert exception.
    public var rpcAlert: MachExceptionRpcAlertInfo? {
        guard type == .rpcAlert else { return nil }
        return MachExceptionRpcAlertInfo(code, subcode)
    }
    
    /// The information associated with the Mach crash exception.
    public var crash: MachExceptionCrashInfo? {
        guard type == .crash else { return nil }
        return MachExceptionCrashInfo(code, subcode)
    }
    
    /// The information associated with the Mach resource exception.
    public var resource: MachExceptionResourceInfo? {
        guard type == .resource else { return nil }
        return MachExceptionResourceInfo(code, subcode)
    }
    
    /// The information associated with the Mach guard exception.
    public var `guard`: MachExceptionGuardInfo? {
        guard type == .guard else { return nil }
        return MachExceptionGuardInfo(code, subcode)
    }
    
    /// The information associated with the Mach corpse notify exception.
    public var corpseNotify: MachExceptionCorpseNotifyInfo? {
        guard type == .corpseNotify else { return nil }
        return MachExceptionCorpseNotifyInfo(code, subcode)
    }
}

extension NSError {
    
    internal subscript<T>(_ key: String) -> T? {
        guard let info = userInfo[key], let value = info as? T else {
            return nil
        }
        return value
    }
}

/// A type describing OS reason namespaces.
public enum OSReasonNamespace: Int32 {
    case invalid
    case jetsam
    case signal
    case codeSigning
    case hangTracer
    case test
    case dyld
    case libxpc
    case objc
    case exec
    case springboard
    case tcc
    case reportCrash
    case coreAnimation
    case aggregated
    case runningBoard
    case assertiond
    case skywalk
    case settings
    case libsystem
    case foundation
    case watchdog
    case metal
    case watchkit
    case `guard`
    case analytics
    case sandbox
    case security
    case endpointSecurity
    case pacException
    case bluetoothChip
}

/// A type describing OS reason.
public typealias OSReason = Int64

// Used by unit tests.
internal func makeNSError(type: exception_type_t,
                 code: mach_exception_data_type_t?,
                 subcode: mach_exception_data_type_t?) -> NSError
{
    var userInfo = [String : Any]()
    if let code = code {
        userInfo[MachExceptionCode] = NSNumber(value: Int64(code))
    }
    if let subcode = subcode {
        userInfo[MachExceptionSubcode] = NSNumber(value: Int64(subcode))
    }
    return NSError(domain: MachExceptionErrorDomain, code: Int(type), userInfo: userInfo)
}
