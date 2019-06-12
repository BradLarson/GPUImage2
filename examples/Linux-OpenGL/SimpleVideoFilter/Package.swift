// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "SimpleVideoFilter",
    dependencies: [
        .package(path: "../../../../GPUImage2")
    ],
    targets: [
        .target(
            name: "SimpleVideoFilter",
            dependencies: ["GPUImage", "GPUImageV4LCamera"],
            path: "Sources")
    ]
)
