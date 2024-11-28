// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APITime",
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "APITime",
            targets: ["APITime"])
    ],
    dependencies: [
        .package(url: "https://github.com/Raw-E/LoggingTime.git", branch: "main")
    ],
    targets: [
        .target(
            name: "APITime",
            dependencies: ["LoggingTime"],
            path: "Sources"),
        .testTarget(
            name: "APITimeTests",
            dependencies: ["APITime"]),
    ]
)
