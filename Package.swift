// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "UI",
    platforms: [
        .iOS(.v14),
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
        .package(
            url: "https://github.com/Juanpe/SkeletonView.git",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .product(name: "Utility", package: "swift-architecture-template-utility"),
                .product(name: "SkeletonView", package: "SkeletonView"),
            ]
        ),
        .testTarget(
            name: "UITests",
            dependencies: ["UI"]
        ),
    ]
)
