// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "miniply-swift",
    products: [
        .library(
            name: "miniply-swift",
            targets: ["miniply-swift"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "miniply-swift",
            dependencies: []),
    ]
)
