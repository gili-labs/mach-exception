// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "swift-exceptions",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "swift-exceptions", targets: ["swift-exceptions", "mach-exceptions"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "swift-exceptions",
            dependencies: [
                .target(name: "mach-exceptions"),
            ]
        ),
        .target(
            name: "mach-exceptions"
        ),
        .testTarget(
            name: "swift-exceptionsTests",
            dependencies: ["swift-exceptions", "mach-exceptions"]
        ),
    ]
)
