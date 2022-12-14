//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorGuard.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation
import mach_exception_helper

/// A type describing the information conveyed by the codes associated with
/// a Mach guard excpetion.
public enum MachExceptionGuardInfo: Equatable {
    
    /// Lingering guard on the process.
    case none
    
    /// The process violated a guarded port protection:
    /// - port: Identifies the guard port.
    /// - reason: The reason for the exception.
    /// - guardId: Identifies the guard that was violated.
    case machPort(port: mach_port_name_t, reason: mach_port_guard_exception_codes, guardId: Int64)
    
    /// The process violated a guarded file protection:
    /// - fileDescriptor: Identifies the file.
    /// - flavor: The flavor of the file guard exception.
    /// - guardId: Identifies the guard that was violated.
    case fileDescriptor(fileDescriptor: Int32, flavor: FileDescriptorFlavor, guardId: Int64)
    
    /// The process violated a guarded user protection:
    /// - namespace: The namespace of the reason for the user guard exception
    /// - reason: The reason for the user guard exception.
    case user(namespace: OSReasonNamespace, reason: OSReason)
    
    /// The process violated a guarded vNode protection. Mach represents files and
    /// directories using a vNode:
    /// - pid: The identifier of the process that violated a guarded vNode protection.
    /// - guardId: Identifies the guard that was violated.
    case vNode(pid: Int32, guardId: VNodeGuardId)
    
    /// The process violated a guarded virtual memory protection:
    /// - offset: The offset into memory causing the virtual memory guard exception.
    case virtualMemory(offset: Int64)
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let guardCode = code, let subcode = subcode else { return nil }
        let code = Code(value: guardCode)
        let type: Int32 = code.type
        switch type {
        case GUARD_TYPE_NONE:
            self = .none
        case GUARD_TYPE_MACH_PORT:
            let port: mach_port_name_t = code.portName
            let reason = mach_port_guard_exception_codes(code.reason)
            self = .machPort(port: port, reason: reason, guardId: subcode)
        case GUARD_TYPE_FD:
            let fileDescriptor: Int32 = code.fileDescriptor
            let flavor = FileDescriptorFlavor(rawValue: code.flavor)
            self = .fileDescriptor(fileDescriptor: fileDescriptor, flavor: flavor, guardId: subcode)
        case GUARD_TYPE_USER:
            guard let namespace = OSReasonNamespace(rawValue: code.namespace) else { return nil }
            self = .user(namespace: namespace, reason: subcode)
        case GUARD_TYPE_VN:
            let guardId = VNodeGuardId(rawValue: subcode)
            self = .vNode(pid: code.pid, guardId: guardId)
        case GUARD_TYPE_VIRT_MEMORY:
            self = .virtualMemory(offset: subcode)
        default:
            return nil
        }
    }
    
    /// The bit fields contained by a code associated with a Mach resource exception
    /// (See darwin-xnu/osfmk/kern/exc\_guard.h) for more information).
    public struct Code: BitFields {
        
        public var value: mach_exception_data_type_t = 0
        
        public static var fields = Fields {
            Field("type", 61, 63)
            Field("flavor", 32, 60)
            Field("target", 0, 31)
            Field("portName", 0, 31)
            Field("reason", 32, 60)
            Field("fileDescriptor", 0, 31)
            Field("namespace", 0, 31)
            Field("pid", 0, 31)
        }
    }
    
    /// The flavor of a Mach file descriptor guard exception.
    public struct FileDescriptorFlavor: OptionSet {
        
        public let rawValue: Int32
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        /// Closed guarded file descriptor.
        public static let close = FileDescriptorFlavor(rawValue: 1 << 0)
        
        /// Duplicated guarded file descriptor.
        public static let dup = FileDescriptorFlavor(rawValue: 1 << 1)
        
        /// Clear close-on-exec.
        public static let noCloseOnExec = FileDescriptorFlavor(rawValue: 1 << 2)
        
        /// Sendmsg of guarded file descriptor.
        public static let socketIPC = FileDescriptorFlavor(rawValue: 1 << 3)
        
        /// Send right for guarded file descriptor.
        public static let filePort = FileDescriptorFlavor(rawValue: 1 << 4)
        
        /// Wrong guard for guarded file descriptor.
        public static let mismatch = FileDescriptorFlavor(rawValue: 1 << 5)
        
        /// Write on guarded file descriptor.
        public static let write = FileDescriptorFlavor(rawValue: 1 << 6)
    }
    
    /// Guard identifier for V-Node guard exception.
    public struct VNodeGuardId: OptionSet {
        
        public let rawValue: Int64
        
        public init(rawValue: Int64) {
            self.rawValue = rawValue
        }
        
        public static let renameTo = VNodeGuardId(rawValue: 1 << 0)
        public static let renameFrom = VNodeGuardId(rawValue: 1 << 1)
        public static let unlink = VNodeGuardId(rawValue: 1 << 2)
        public static let writeOther = VNodeGuardId(rawValue: 1 << 3)
        public static let truncateOther = VNodeGuardId(rawValue: 1 << 4)
        public static let link = VNodeGuardId(rawValue: 1 << 5)
        public static let exchangeData = VNodeGuardId(rawValue: 1 << 6)
    }
}
