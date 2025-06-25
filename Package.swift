// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdf22png",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Main CLI executable
        .executable(
            name: "pdf22png-swift",
            targets: ["PDF22PNGSwiftCLI"]
        ),
        // Core library that can be used by other Swift packages
        .library(
            name: "PDF22PNGCore",
            targets: ["PDF22PNGCore"]
        )
    ],
    dependencies: [
        // Swift Argument Parser for CLI
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Core functionality library
        .target(
            name: "PDF22PNGCore",
            dependencies: [],
            path: "Sources/PDF22PNGCore"
        ),
        // Swift CLI implementation
        .executableTarget(
            name: "PDF22PNGSwiftCLI",
            dependencies: [
                "PDF22PNGCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/PDF22PNGCLI"
        ),
        // Objective-C compatibility layer
        .target(
            name: "PDF22PNGObjCBridge",
            dependencies: ["PDF22PNGCore"],
            path: "Sources/PDF22PNGObjCBridge",
            publicHeadersPath: "include"
        ),
        // Tests
        .testTarget(
            name: "PDF22PNGCoreTests",
            dependencies: ["PDF22PNGCore"],
            path: "Tests/PDF22PNGCoreTests"
        ),
        .testTarget(
            name: "PDF22PNGCLITests",
            dependencies: ["PDF22PNGSwiftCLI"],
            path: "Tests/PDF22PNGCLITests"
        )
    ]
)