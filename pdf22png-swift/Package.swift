// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "pdf22png-swift",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "pdf22png-swift",
            targets: ["pdf22png-swift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "pdf22png-swift",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources"
        )
    ]
)
