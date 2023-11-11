// swift-tools-version: 5.8

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
            url: "https://github.com/miyoshitakaaki/swift-architecture-template-utility",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.2.0"),
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
