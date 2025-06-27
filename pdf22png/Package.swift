// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "pdf22png",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "pdf22png",
            targets: ["pdf22png"]
        ),
        .library(
            name: "ScaleUtilities",
            targets: ["ScaleUtilities"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "pdf22png",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ScaleUtilities"
            ],
            path: "Sources/pdf22png"
        ),
        .target(
            name: "ScaleUtilities",
            path: "Sources/Utils"
        ),
        .testTarget(
            name: "ScaleUtilitiesTests",
            dependencies: ["ScaleUtilities"],
            path: "Tests/ScaleUtilitiesTests"
        )
    ]
)
