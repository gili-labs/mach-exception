// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "mach-exception",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "mach-exception",
            targets: [
                "mach-exception",
                "mach-exception-helper",
            ]
        ),
        .plugin(
            name: "MachInterfaceGenerator",
            targets: [
                "MachInterfaceGenerator"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "mach-exception",
            dependencies: [
                .target(name: "mach-exception-helper"),
            ]
        ),
        .target(
            name: "mach-exception-helper",
            dependencies: [
            ]
//            sources: [
//                "mach_exception_helper.m",
//                "mach_excServer.c",
//                "mach_fp_exceptions.c",
//                "mach_msg_server_once.c",
//                "my.defs",
//            ]
//            plugins: [
//                "MachInterfaceGenerator",
//            ]
        ),
        .testTarget(
            name: "mach-exceptionTests",
            dependencies: [
                "mach-exception",
                "mach-exception-helper",
            ]
        ),
        .plugin(
            name: "MachInterfaceGenerator",
            capability: .command(
                intent: .custom(
                    verb: "mach-interface-generator",
                    description: "Generates server-side code from a Mach .defs file."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "This command generates source code files.")
                ]
            )
        ),
        .executableTarget(
            name: "MachInterfaceGeneratorTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
//        .plugin(name: "MachInterfaceGenerator",
//                capability: .buildTool(),
//                dependencies: [
//                    "MachInterfaceGeneratorTool",
//                ]
//        ),
    ]
)
