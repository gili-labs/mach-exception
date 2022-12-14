//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorBadInstruction.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

/// Type representing information associated with a Mach bad instruction exception.
public struct MachExceptionBadInstructionInfo {
    
    /// The cause of the exception/fault.
    public let code: MachExceptionBadInstructionCode
    
#if arch(arm) || arch(arm64)
    /// The instruction that caused the fault.
    public let instruction: UInt64
#elseif arch(i386) || arch(x86_64)
    /// If the trapno is T\_PAGE\_FAULT and the fault was not successful handled, the virtual address that caused the
    /// fault; otherwise, `0`.
    public let address: UInt64
#endif
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let code = code, let subcode = subcode,
              let badInstructionCode = MachExceptionBadInstructionCode(code: code)
        else {
            return nil
        }
        self.code = badInstructionCode
#if arch(arm) || arch(arm64)
        self.instruction = UInt64(subcode)
#elseif arch(i386) || arch(x86_64)
        self.address = UInt64(subcode)
#endif
    }
}

#if arch(arm) || arch(arm64)
public enum MachExceptionBadInstructionCode: Equatable {
    
    case undefined
    
    public init?(code: mach_exception_data_type_t) {
        let code = Int32(code)
        switch code {
        case EXC_ARM_UNDEFINED: self = .undefined
        default: return nil
        }
    }
}
#elseif arch(i386) || arch(x86_64)
public enum MachExceptionBadInstructionCode: Equatable {
    
    /// Invalid TSS (Task State Segment) fault.
    case invalidTSS
    
    /// Segment not present fault.
    case segmentNotPresent
    
    /// Stack fault.
    case stackFault
    
    /// Invalid opcode, which includes instructions that are not AVX512 instructions, and instructions that are AVX512
    /// instructions on processors that do not support the AVX512 extension.
    case invalidOpcode
    
    /// Page fault.
    case pageFault(kernResult: Int32)
    
    public init?(code: mach_exception_data_type_t) {
        let code = Int32(code)
        switch code {
        case EXC_I386_INVTSSFLT: self = .invalidTSS
        case EXC_I386_SEGNPFLT: self = .segmentNotPresent
        case EXC_I386_STKFLT: self = .stackFault
        case EXC_I386_INVOP: self = .invalidOpcode
        case KERN_SUCCESS...KERN_RETURN_MAX: self = .pageFault(kernResult: code)
        default: return nil
        }
    }
}
#endif
