// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "UI",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "UI",
            targets: ["UI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/miyoshi-cq/swift-architecture-template-utility",
            .upToNextMajor(from: "0.1.0")
        ),
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .product(name: "Utility", package: "swift-architecture-template-utility"),
            ]
        ),
        .testTarget(
            name: "UITests",
            dependencies: ["UI"]
        ),
    ]
)
