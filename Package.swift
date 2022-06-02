// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UI",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "UI",
            targets: ["UI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/miyoshi-cq/swift-architecture-template-utility",
            .upToNextMajor(from: "0.1.0")
        ),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Utility", package: "swift-architecture-template-utility"),
            ]),
        .testTarget(
            name: "UITests",
            dependencies: ["UI"]),
    ]
)
