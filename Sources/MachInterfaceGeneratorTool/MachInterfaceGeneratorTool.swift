//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// 
// File.swift
// Created by Patrick Gili on 1/15/23.
//

import Foundation
import ArgumentParser

@main
struct MachInterfaceGeneratorTool: ParsableCommand {
    @Flag(help: "Generate server-side RPC source code files.")
    var server = false
    
    @Flag(help: "Generate user-side RPC source code files.")
    var user = false
    
    @Option(help: "The path of the directory into which to generate source code files.")
    var outputPath: String?
    
    @Option(help: "The path of a specific Mach interface compiler to use for generating source code files.")
    var mig: String?

    @Argument(help: "The path of the Mach interface definitions file.")
    var inputPath: String
    
    mutating func run() throws {
        let input = Path(inputPath)
        guard input.extension == "defs" else {
            return
        }
        
        let output = Path(outputPath ?? input.removingLastComponent().string)
        
        let serverSideRPCSourcePath: Path
        let serverSideRPCHeaderPath: Path
        if server {
            serverSideRPCSourcePath = output.appending(input.stem + "Server.c")
            serverSideRPCHeaderPath = output.appending(input.stem + "Server.h")
        } else {
            serverSideRPCSourcePath = Path("/dev/null")
            serverSideRPCHeaderPath = Path("/dev/null")
        }
        
        let userSideRPCSourcePath: Path
        let userSideRPCHeaderPath: Path
        if user {
            userSideRPCSourcePath = output.appending(input.stem + "User.c")
            userSideRPCHeaderPath = output.appending(input.stem + "User.h")
        } else {
            userSideRPCSourcePath = Path("/dev/null")
            userSideRPCHeaderPath = Path("/dev/null")
        }
        
        let sdkPath = Path( "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs")
        
        let debugString = """
                ***
                mig: \(mig ?? "/usr/bin/mig")
                input: \(input.string)
                output: \(output.string)
                serverSideRPCSourcePath: \(serverSideRPCSourcePath.string)
                serverSideRPCHeaderPath: \(serverSideRPCHeaderPath.string)
                userSideRPCSourcePath:   \(userSideRPCSourcePath.string)
                userSideRPCHeaderPath:   \(userSideRPCHeaderPath.string)
                sdkPath: \(sdkPath.string)
                """
        print(debugString)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: mig ?? "/usr/bin/mig")
        process.arguments = [
            "-server", serverSideRPCSourcePath.string,
            "-sheader", serverSideRPCHeaderPath.string,
            "-user", userSideRPCSourcePath.string,
            "-header", userSideRPCHeaderPath.string,
            //"-isysroot", sdkPath.string,
            "-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include",
            input.string
        ]
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if !(process.terminationReason == .exit && process.terminationStatus == 0) {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            print(problem)
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorText = String(decoding: errorData, as: UTF8.self)
            
            print("*** ERROR ***")
            print(errorText)
            
            throw ExitCode(process.terminationStatus)
        }
        
        if server {
            wrapFile(serverSideRPCSourcePath)
            wrapFile(serverSideRPCHeaderPath)
        }
        
        if user {
            wrapFile(userSideRPCSourcePath)
            wrapFile(userSideRPCHeaderPath)
        }
    }
    
    func wrapFile(_ path: Path) {
        let file = URL(filePath: path.string)
        let header = """
            #ifdef __APPLE__
            #import "TargetConditionals.h"
            #if TARGET_OS_OSX || TARGET_OS_IOS
            \n
            """
        let footer = """

            #endif /* TARGET_OS_OSX || TARGET_OS_IOS */
            #endif /* __APPLE__ */
            """
        do {
            var contents = try String(contentsOf: file, encoding: .utf8)
            contents = header + contents + footer
            try contents.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
    }
}
