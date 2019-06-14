// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "SimpleImageFilter",
    dependencies: [
        .package(path: "../../../../GPUImage2")
    ],
    targets: [
        .target(
            name: "SimpleImageFilter",
            dependencies: ["GPUImage"],
            path: "Sources")
    ]
)
