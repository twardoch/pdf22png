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
            name: "pdf22png",
            targets: ["pdf22png"]
        )
    ],
    dependencies: [
        // Swift Argument Parser for CLI
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "pdf22png",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "src",
            sources: ["main.swift"],
            exclude: ["pdf22png.m", "utils.m", "pdf22png.h", "utils.h", "errors.h", "llms.txt", "Makefile", "*.o"]
        )
    ]
)