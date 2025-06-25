// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdf22png",
    platforms: [
        .macOS(.v10_15) // Based on existing requirements
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "pdf22png",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/pdf22png"
        ),
        .testTarget(
            name: "pdf22pngTests",
            dependencies: ["pdf22png"],
            path: "Tests/pdf22pngTests"
        ),
    ]
)
