//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// machExceptionErrorResource.swift
// Created by Patrick Gili on 12/4/22.
//

import Foundation
import mach_exception_helper

/// A type describing the information conveyed by the codes associated with
/// a Mach resource exception.
public enum MachExceptionResourceInfo: Equatable {
    
    /// Sent by the kernel when the CPU monitor has been tripped:
    /// - flavor: The reason for the CPU resource exception.
    /// - interval: The observation interval (seconds).
    /// - limit: The CPU limit (percentage).
    /// - utilitization: The measured utilization (percentage).
    case cpu(flavor: CpuFlavor, interval: Int64, limit: Int64, utilization: Int64)
    
    /// Sent by the kernel when the platform idle wakeup monitor has been tripped:
    /// - flavor: The reason for the wakeups resource exception.
    /// - interval: The observation interval (seconds).
    /// - permitted: The permitted number of wakeups (per second).
    /// - wakeups: The observed number of wakeups (per second).
    case wakeups(flavor: WakeupsFlavor, interval: Int64, permitted: Int64, wakeups: Int64)
    
    /// Sent by the kernel when a task crosses its high watermark memory limit.
    /// - flavor: The reason for the memory resource exception.
    /// - highwaterMark: The high watermark memory limit (MB).
    case memory(flavor: MemoryFlavor, highWatermark: Int64)
    
    /// Sent by the kernel when a task crosses its I/O limits.
    /// - flavor: The reason for the I/O resource exception.
    /// - limit: The I/O limit (MB).
    /// - interval: The observation interval (seconds).
    /// - count: The observed I/O count (MB).
    case io(flavor: IOFlavor, interval: Int64, limit: Int64, count: Int64)
    
    /// Sent by the kernel when a task crosses its thread limit.
    /// - flavor: The reason for the thread resource exception.
    /// - count: The observed thread count.
    case threads(flavor: ThreadsFlavor, count: Int64)
    
    internal init?(_ code: mach_exception_data_type_t?, _ subcode: mach_exception_data_type_t?) {
        guard let resourceCode = code, let resourceSubcode = subcode else { return nil }
        let code = Code(value: resourceCode)
        let subcode = Subcode(value: resourceSubcode)
        let type: Int32 = code.type
        switch type {
        case RESOURCE_TYPE_CPU:
            guard let flavor = CpuFlavor(rawValue: code.flavor) else { return nil }
            self = .cpu(flavor: flavor,
                        interval: code.cpuInterval,
                        limit: code.cpuLimit,
                        utilization: subcode.cpuUtilization)
        case RESOURCE_TYPE_WAKEUPS:
            guard let flavor = WakeupsFlavor(rawValue: code.flavor) else { return nil }
            self = .wakeups(flavor: flavor,
                            interval: code.wakeupsInterval,
                            permitted: code.wakeupsPermitted,
                            wakeups: subcode.wakeupsObserved)
        case RESOURCE_TYPE_MEMORY:
            guard let flavor = MemoryFlavor(rawValue: code.flavor) else { return nil }
            self = .memory(flavor: flavor, highWatermark: code.memoryHWMLimit)
        case RESOURCE_TYPE_IO:
            guard let flavor = IOFlavor(rawValue: code.flavor) else { return nil }
            self = .io(flavor: flavor,
                       interval: code.ioInterval,
                       limit: code.ioLimit,
                       count: subcode.ioCount)
        case RESOURCE_TYPE_THREADS:
            guard let flavor = ThreadsFlavor(rawValue: code.flavor) else { return nil }
            self = .threads(flavor: flavor, count: code.threadsCount)
        default:
            return nil
        }
    }
    
    /// The bit fields contained by a code associated with a Mach resource exception
    /// (See darwin-xnu/osfmk/kern/exc\_resource.h) for more information).
    public struct Code: BitFields {
        
        public var value: mach_exception_data_type_t = 0

        public static var fields = Fields {
            Field("type", 61, 63)
            Field("flavor", 58, 60)
            Field("cpuInterval", 7, 31)
            Field("cpuLimit", 0, 6)
            Field("wakeupsInterval", 20, 31)
            Field("wakeupsPermitted", 0, 19)
            Field("memoryHWMLimit", 0, 12)
            Field("ioInterval", 15, 31)
            Field("ioLimit", 0, 14)
            Field("threadsCount", 0, 30)
        }
    }
    
    /// The bit fields contained by a subcode associated with a Mach resource exception
    /// (See darwin-xnu/osfmk/kern/exc\_resource.h) for more information).
    public struct Subcode: BitFields {
        
        public var value: mach_exception_data_type_t = 0

        public static var fields = Fields {
            Field("cpuUtilization", 0, 6)
            Field("wakeupsObserved", 0, 6)
            Field("ioCount", 0, 14)
        }
    }

    /// The flavor of a Mach CPU resource exception.
    public enum CpuFlavor: Int64 {
        /// A thread has consumed an excessive percentage of the CPU.
        case monitor = 1
        
        /// A thread has fatally consumed an excessive percentage of the CPU.
        case monitorFatal = 2
    }
    
    /// The flavor of a Mach wakeups resource exception.
    public enum WakeupsFlavor: Int64 {
        /// A process has experienced an excessive number of wakeups.
        case monitor = 1
    }
    
    /// The flavor of a Mach memory resource exception.
    public enum MemoryFlavor: Int64 {
        /// A process has consumed memory exceeding the high watermark.
        case highWatermark = 1
    }
    
    /// The flavor of a Mach I/O resource exception.
    public enum IOFlavor: Int64 {
        /// A process has performed an excessive number of physical writes.
        case physicalWrites = 1
        
        /// A process has performed an excessive number of logical writes.
        case logicalWrites = 2
    }
    
    /// The flavor of a Mach threads resource exception.
    public enum ThreadsFlavor: Int64 {
        /// A process has created a number of threads exceeding the high watermark.
        case highWatermark = 1
    }
}
