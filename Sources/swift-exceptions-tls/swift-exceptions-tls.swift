//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// swift-exceptions
// swift-exceptions-tls.swift
// Created by Patrick Gili on 6/24/22.
//

import Foundation

public enum ExceptionContext {
    @TaskLocal
    public static var context: ExceptionContext?
}
