//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorCorpseNotify.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

///
public enum MachExceptionCorpseNotifyInfo: Equatable {

    /// The last thread associated with a task has terminated, the task has an association with a BSD process, and
    /// crash information is available.
    case crash(namespace: OSReasonNamespace, reason: OSReason)
    
    /// The task is a corpse fork resulting from a resource exception. Resolve
    case resource(info: MachExceptionResourceInfo)
    
    /// The task is a corpse fork resulting from a guard exception.
    case `guard`(info: MachExceptionGuardInfo)
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let code = code, let subcode = subcode else {
            return nil
        }
        switch Int32(code) {
        case EXC_CRASH:
            let crashSubcode = Subcode(value: subcode)
            guard let namespace = OSReasonNamespace(rawValue: crashSubcode.namespace) else {
                return nil
            }
            let reason: OSReason = crashSubcode.reason
            self = .crash(namespace: namespace, reason: reason)
        case EXC_RESOURCE:
            guard let info = MachExceptionResourceInfo(subcode, 0) else { return nil }
            self = .resource(info: info)
        case EXC_GUARD:
            guard let info = MachExceptionGuardInfo(subcode, 0) else { return nil }
            self = .guard(info: info)
        default: return nil
        }
    }

    ///
    public struct Subcode: BitFields {

        public var value: mach_exception_data_type_t = 0

        public static var fields = Fields {
            Field("reason", 0, 31)
            Field("namespace", 32, 63)
        }
    }
}
