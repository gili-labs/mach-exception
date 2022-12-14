//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorArithmetic.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

/// Type representing information associated with a Mach arithmetic exception
public struct MachExceptionArithmeticInfo {
    
    /// The cause of the arithmetic exception.
    public let code: MachExceptionArithmeticCode
    
#if arch(arm) || arch(arm64)
    /// The instruction that caused the fault.
    public let instruction: UInt64
#elseif arch(i386) || arch(x86_64)
    /// If `code` is `floatingPointError`, the contents of the FPU's CSR. If `code` is `simdOperationError`, the
    /// contents of the SSE MXCSR.
    public let csr: UInt64
#endif
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let code = code, let subcode = subcode,
              let arithmeticCode =  MachExceptionArithmeticCode(code: code)
        else {
            return nil
        }
        self.code = arithmeticCode
#if arch(arm) || arch(arm64)
        self.instruction = UInt64(subcode)
#elseif arch(i386) || arch(x86_64)
        self.csr = UInt64(subcode)
#endif
    }
}

#if arch(arm) || arch(arm64)
public enum MachExceptionArithmeticCode: Equatable {
    
    /// Floating-point underflow.
    case underflow
        
    /// Floating-point overflow.
    case overflow
    
    /// Invalid floating-point operation.
    case invalidOperation
    
    /// Floating-point divide-by-zero error.
    case divideError

    /// Floating-point denormal input.
    case denormalInput

    /// Inexact floating-point result.
    case inexactResult
    
    /// Undefined error.
    case undefined
    
    public init?(code: mach_exception_data_type_t) {
        let code = Int32(code)
        switch code {
        case EXC_ARM_FP_UF: self = .underflow
        case EXC_ARM_FP_OF: self = .overflow
        case EXC_ARM_FP_IO: self = .invalidOperation
        case EXC_ARM_FP_DZ: self = .divideError
        case EXC_ARM_FP_ID: self = .denormalInput
        case EXC_ARM_FP_IX: self = .inexactResult
        case EXC_ARM_FP_UNDEFINED: self = .undefined
        default: return nil
        }
    }
}
#elseif arch(i386) || arch(x86_64)
public enum MachExceptionArithmeticCode: Equatable {
    
    /// Floating point divide-by-zero error.
    case divideError
    
    /// INTO instruction caused an overflow.
    case overflow
    
    /// Floating-point unit not availble.
    case noFPU
    
    /// Floating-point error.
    case floatingPointError
    
    /// SIMD operation error.
    case simdOperationError
    
    public init?(code: mach_exception_data_type_t) {
        let code = Int32(code)
        switch code {
        case EXC_I386_DIV: self = .divideError
        case EXC_I386_INTO: self = .overflow
        case EXC_I386_NOEXT: self = .noFPU
        case EXC_I386_EXTERR: self = .floatingPointError
        case EXC_I386_SSEEXTERR: self = .simdOperationError
        default: return nil
        }
    }
}
#endif
