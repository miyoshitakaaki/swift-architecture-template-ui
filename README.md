# UI

UI Components

## Intoroduction

[Swift Package Manager](https://www.swift.org/package-manager/) is supported.

### Into Project

add package into `Package Dependencies`

### Into Package

```swift
let package = Package(
    name: "Sample",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "Sample",
            targets: ["Sample"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/takaakimiyoshi/swift-architecture-template-ui",
            .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .target(
            name: "Sample",
            dependencies: [
                .product(name: "UI", package: "swift-architecture-template-ui"),
            ]
        ),
        .testTarget(
            name: "SampleTests",
            dependencies: ["Sample"]
        ),
    ]
)
```

### Usage

`import UI`

## Requirements

- Xcode 14.3.1 or later
- iOS 14 or later

## Documentation

- [Create List UI](https://miyoshi-cq.github.io/swift-architecture-template-ui/documentation/ui/listusage/)
- [Create multi cell collection UI](https://miyoshi-cq.github.io/swift-architecture-template-ui/documentation/ui/diffablecollectionusage/)
- [Create Form and FormConfirm UI](https://miyoshi-cq.github.io/swift-architecture-template-ui/documentation/ui/formusage/)
- [Create Webview](https://miyoshi-cq.github.io/swift-architecture-template-ui/documentation/ui/webviewusage)

## Generate docs
- `make` or `make create_doc`

## Code Format

`swiftformat .`

## Versioning

[Semantic Versioning](https://semver.org/)
