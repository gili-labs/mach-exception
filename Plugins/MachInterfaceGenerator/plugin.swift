import PackagePlugin
import Foundation

var logs: [String] = []

@main
struct MachInterfaceGenerator: CommandPlugin {

    func performCommand(context: PluginContext, arguments: [String]) async throws
    {
        let mig = try context.tool(named: "mig")

        for target in context.package.targets {
            let fileManager = FileManager.default
            let inputPaths = try fileManager.contentsOfDirectory(atPath: target.directory.string)
                .map { Path(target.directory.string + "/" + $0) }
                .filter { $0.extension == "defs" }

            for inputPath in inputPaths {
                let serverSideRPCSourceName = inputPath.stem + "Server.c"
                let serverSideRPCHeaderName = inputPath.stem + "Server.h"

                let process = Process()
                let executable = try context.tool(named: "MachInterfaceGeneratorTool").path
                process.executableURL = URL(fileURLWithPath: executable.string)

                process.arguments = [
                    "--server",
                    "--mig", mig.path.string,
                    "--output-path", target.directory.string,
                    inputPath.string
                ]
                log(executable.string)
                for argument in process.arguments! {
                    log(argument)
                }
                try process.run()
                process.waitUntilExit()

                let displayName = """
                            Generating \(serverSideRPCSourceName) and \(serverSideRPCHeaderName) \
                            from \(inputPath.lastComponent)
                            """
                if process.terminationReason == .exit && process.terminationStatus == 0 {
                    log(displayName)
                } else {
                    let problem = "\(process.terminationReason):\(process.terminationStatus)"
                    log(problem)
                    Diagnostics.error("Mach Interface Generator invocation failed: \(problem)")
                }
            }
        }
    }

    func log(_ message: String) {
        logs.append(message)
        printLogs()
    }

    func printLogs() {
        do {
            try logs
                .joined(separator: "\n")
                .write(toFile: "logs", atomically: true, encoding: .utf8)
        } catch {
            // ignore
        }
    }
}

//@main
//struct MachInterfaceGenerator: BuildToolPlugin {
//
//    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
//        guard let target = target as? ClangSourceModuleTarget else {
//            return []
//        }
//        return try target.sourceFiles(withSuffix: ".defs").map { sourceFile in
//            let inputPath = sourceFile.path
//            let serverSideRPCSourceName = inputPath.stem + "Server.c"
//            let serverSideRPCHeaderName = inputPath.stem + "Server.h"
//            let serverSideRPCSourcePath = context.pluginWorkDirectory.appending(serverSideRPCSourceName)
//            let serverSideRPCHeaderPath = context.pluginWorkDirectory.appending(serverSideRPCHeaderName)
//
//            let mig = try context.tool(named: "mig").path
//
//            let arguments = [
//                "--server",
//                "--mig", mig.string,
//                "--output-path", context.pluginWorkDirectory.string,
//                inputPath.string
//            ]
//
//            let displayName = """
//                Generating \(serverSideRPCSourceName) and \(serverSideRPCHeaderName) \
//                from \(inputPath.lastComponent)
//                """
//
//            let executable = try context.tool(named: "MachInterfaceGeneratorTool").path
//
//            return .buildCommand(displayName: displayName,
//                                 executable: executable,
//                                 arguments: arguments,
//                                 inputFiles: [inputPath],
//                                 outputFiles: [serverSideRPCSourcePath, serverSideRPCHeaderPath])
//        }
//    }
//}
