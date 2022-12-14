//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorBadAccess.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

/// Type representing information associated with a Mach bad access exception.
public struct MachExceptionBadAccessInfo {
    
    /// The cause of the exception/fault.
    public let code: MachExceptionBadAccessCode
    
#if arch(arm) || arch(arm64)
    /// The memory address of the bad access.
#elseif arch(i386) || arch(x86_64)
    /// If the trapno is T\_GENERAL\_PROTECTION and the fault condition was detected while loading a segment descriptor,
    /// the segment selector to or IDT vector number for the descriptor; otherwise, `0`.
#endif
    public let address: UInt64
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let code = code, let subcode = subcode,
              let badAccessCode =  MachExceptionBadAccessCode(code: code)
        else {
            return nil
        }
        self.code = badAccessCode
        self.address = UInt64(subcode)
    }
}

/// Type representing the code of a Mach bad access exception.
#if arch(arm) || arch(arm64)
public enum MachExceptionBadAccessCode: Equatable {
    
    // VM fault.
    case vmFault(kernResult: Int32)
    
    // Data access alignment fault.
    case dataAccessAlignment
    
    /// Watchpoint exception.
    case dataAccessDebug
    
    /// Stack pointer alignment fault.
    case stackPointerAlignment
    
    /// SWP instruction data abort.
    case swpInstruction
    
    /// Pointer authentication failure.
    case pointerAuthenticationFailure

    public init?(code: mach_exception_data_type_t) {
        let code = Int32(code)
        switch code {
        case EXC_ARM_DA_ALIGN: self = .dataAccessAlignment
        case EXC_ARM_DA_DEBUG: self = .dataAccessDebug
        case EXC_ARM_SP_ALIGN: self = .stackPointerAlignment
        case EXC_ARM_SWP: self = .swpInstruction
        case EXC_ARM_PAC_FAIL: self = .pointerAuthenticationFailure
        case KERN_SUCCESS...KERN_RETURN_MAX: self = .vmFault(kernResult: code)
        default: return nil
        }
    }
}
#elseif arch(i386) || arch(x86_64)
public enum MachExceptionBadAccessCode {
    
    /// FPU overran segment fault.
    case fpuSegmentFault
    
    /// General protection fault.
    case generalProtectionFault

    public init?(code: mach_exception_data_type_t) {
        let code = Int32(code)
        switch code {
        case VM_PROT_READ | VM_PROT_EXECUTE: self = .fpuSegmentFault
        case EXC_I386_GPFLT: self = .generalProtectionFault
        default: return nil
        }
    }
}
#endif
