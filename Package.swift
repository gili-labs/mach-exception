// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "mach-exception",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "mach-exception",
            targets: [
                "mach-exception",
                "mach-exception-helper",
            ]
        ),
    ],
    dependencies: [
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
        ),
        .testTarget(
            name: "mach-exceptionTests",
            dependencies: [
                "mach-exception",
                "mach-exception-helper",
            ]
        ),
    ]
)
