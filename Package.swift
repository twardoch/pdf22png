// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pdf22png",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "pdf22png",
            targets: ["pdf22png"]
        )
    ],
    targets: [
        .executableTarget(
            name: "pdf22png",
            dependencies: [],
            path: "src",
            exclude: [
                "test-framework.swift",
                "Makefile"
            ]
        ),
        .testTarget(
            name: "pdf22pngTests",
            dependencies: ["pdf22png"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)