// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyToolLibrary",
//    platforms: [
//    .macOS(.v13)
//    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MyToolLibrary",
            targets: ["MyToolLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MyToolLibrary"),
        .executableTarget(
            name: "MyToolCLI",
            dependencies: [
                "MyToolLibrary",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "MyToolLibraryTests",
            dependencies: ["MyToolLibrary"]),
        .testTarget(
            name: "MyToolCLITests",
            dependencies: ["MyToolCLI"]),
    ]
)
