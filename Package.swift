// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "swift-exceptions",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "swift-exceptions",
            targets: [
                "swift-exceptions",
                "mach-exceptions",
                "swift-exceptions-tls",
            ]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "swift-exceptions",
            dependencies: [
                .target(name: "mach-exceptions"),
                .target(name: "swift-exceptions-tls"),
            ]
        ),
        .target(
            name: "mach-exceptions",
            dependencies: [
                .target(name: "swift-exceptions-tls"),
            ]
        ),
        .target(
            name: "swift-exceptions-tls"
        ),
        .testTarget(
            name: "swift-exceptionsTests",
            dependencies: [
                "swift-exceptions",
                "mach-exceptions",
            ]
        ),
    ]
)
