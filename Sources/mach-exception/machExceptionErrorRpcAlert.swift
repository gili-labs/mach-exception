//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorRprcAlert.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation

public struct MachExceptionRpcAlertInfo {
    
    /// The code associated with a RPC alert exception should be `0xff000001`. However, this type reflects it for
    /// // convenience.
    public let code: mach_exception_data_type_t
    
    /// The identifier assigned to the process making the Mach syscall.
    public let pid: Int64
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let code = code, let subcode = subcode,
              code == 0xff000001
        else {
            return nil
        }
        self.code = code
        self.pid = Int64(subcode)
    }
}
