//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// File.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

// MARK: - Mach Exception Type

/// A set of Mach exceptions types.
public struct MachExceptionTypes: OptionSet {
    
    /// The Mach exception mask, which is a 32-bit integer-value representing a set of Mach
    /// exception types.
    public let rawValue: Int32
    
    /// Create a set of Mach exception types from a Mach exception mask.
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    /// Mach exception thrown when the excecution of code attempts to read or write memory that
    /// it does not have read or write access.
    public static let badAccess        = MachExceptionTypes(rawValue: 1 << EXC_BAD_ACCESS)
    
    /// Mach exception thrown when the processor encounters an illegal or undefined instruction
    /// or operatand.
    public static let badInstruction   = MachExceptionTypes(rawValue: 1 << EXC_BAD_INSTRUCTION)
    
    /// Mach exception thrown when the processor attempts to perform an arithmetic operation,
    /// but cannot for numerous reasons (e.g., divide-by-zero).
    public static let arithmetic       = MachExceptionTypes(rawValue: 1 << EXC_ARITHMETIC)
    
    /// Mach exception thrown when emulation support instruction encountered.
    public static let emulation        = MachExceptionTypes(rawValue: 1 << EXC_EMULATION)
    
    /// Mach exception thrown when software raises an exception.
    public static let software         = MachExceptionTypes(rawValue: 1 << EXC_SOFTWARE)
    
    /// Mach exception thrown when the processor encounters a breakpoint.
    public static let breakpoint       = MachExceptionTypes(rawValue: 1 << EXC_BREAKPOINT)
    
    /// Mach exception thrown for a system call.
    public static let syscall          = MachExceptionTypes(rawValue: 1 << EXC_SYSCALL)
    
    /// Mach exception thrown for a Mach system call.
    public static let machSyscall      = MachExceptionTypes(rawValue: 1 << EXC_MACH_SYSCALL)
    
    /// Mach exception thrown when the kernel encounters a RPC alert.
    public static let rpcAlert         = MachExceptionTypes(rawValue: 1 << EXC_RPC_ALERT)
    
    /// Mach exception thrown upon the abnormal exit of a process.
    public static let crash            = MachExceptionTypes(rawValue: 1 << EXC_CRASH)
    
    /// Mach exception thrown when the kernel encounters a resource consumption limit.
    public static let resource         = MachExceptionTypes(rawValue: 1 << EXC_RESOURCE)
    
    /// Mach exception thrown upon the violation of a guarded resource protection.
    public static let `guard`          = MachExceptionTypes(rawValue: 1 << EXC_GUARD)
    
    /// Mach exception thrown upon the abnormal exit of a process into a corpse state.
    public static let corpseNotify     = MachExceptionTypes(rawValue: 1 << EXC_CORPSE_NOTIFY)
    
    /// The `exception_mask_t` value corresponding to this set of Mach exceptions.
    public var exceptionMask: exception_mask_t {
        exception_mask_t(rawValue)
    }
}

/// A Mach exception type.
public enum MachExceptionType: RawRepresentable {
        
    /// Mach exception thrown when the excecution of code attempts to read or write memory that
    /// it does not have read or write access.
    case badAccess
    
    /// Mach exception thrown when the processor encounters an illegal or undefined instruction
    /// or operatand.
    case badInstruction
    
    /// Mach exception thrown when the processor attempts to perform an arithmetic operation,
    /// but cannot for numerous reasons (e.g., divide-by-zero).
    case arithmetic
    
    /// Mach exception thrown when emulation support instruction encountered.
    case emulation
    
    /// Mach exception thrown when software raises an exception.
    /// - code: 0x0000-0xffff reserved to hardware, 0x10000-0x1ffff reserved for OS emulation.
    case software
    
    /// Mach exception thrown when the processor encounters a breakpoint.
    case breakpoint
    
    /// Mach exception thrown for a system call.
    case syscall
    
    /// Mach exception thrown for a Mach system call.
    case machSyscall
    
    /// Mach exception thrown when the kernel encounters a RPC alert.
    case rpcAlert
    
    /// Mach exception thrown upon the abnormal exit of a process.
    case crash
    
    /// Mach exception thrown when the kernel encounters a resource consumption limit.
    case resource
    
    /// Mach exception thrown upon the violation of a guarded resource protection.
    case `guard`
    
    /// Mach exception thrown upon the abnormal exit of a process into a corpse state.
    case corpseNotify
    
    public typealias RawValue = exception_type_t

    public init?(rawValue: exception_type_t) {
        switch rawValue {
        case EXC_BAD_ACCESS: self = .badAccess
        case EXC_BAD_INSTRUCTION: self = .badInstruction
        case EXC_ARITHMETIC: self = .arithmetic
        case EXC_EMULATION: self = .emulation
        case EXC_SOFTWARE: self = .software
        case EXC_BREAKPOINT: self = .breakpoint
        case EXC_SYSCALL: self = .syscall
        case EXC_MACH_SYSCALL: self = .machSyscall
        case EXC_RPC_ALERT: self = .rpcAlert
        case EXC_CRASH: self = .crash
        case EXC_RESOURCE: self = .resource
        case EXC_GUARD: self = .`guard`
        case EXC_CORPSE_NOTIFY: self = .corpseNotify
        default: return nil
        }
    }

    public var rawValue: exception_type_t {
        switch self {
        case .badAccess: return EXC_BAD_ACCESS
        case .badInstruction: return EXC_BAD_INSTRUCTION
        case .arithmetic: return EXC_ARITHMETIC
        case .emulation: return EXC_EMULATION
        case .software: return EXC_SOFTWARE
        case .breakpoint: return EXC_BREAKPOINT
        case .syscall: return EXC_SYSCALL
        case .machSyscall: return EXC_MACH_SYSCALL
        case .rpcAlert: return EXC_RPC_ALERT
        case .crash: return EXC_CRASH
        case .resource: return EXC_RESOURCE
        case .guard: return EXC_GUARD
        case .corpseNotify: return EXC_CORPSE_NOTIFY
        }
    }
}
