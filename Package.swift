// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)
let platformDepedencies: [Package.Dependency] = []
let platformExcludes = ["iOS", "Linux", "Operations/Shaders"]
#elseif os(iOS)
let platformDepedencies: [Package.Dependency] = []
let platformExcludes = ["Linux", "Mac", "Operations/Shaders"]
#elseif os(Linux)
// TODO: Add back in RPi support
let platformDepedencies: [Package.Dependency] = [.package(url: "https://github.com/BradLarson/COpenGL.git", from: "1.0.2"), .package(url: "https://github.com/BradLarson/CFreeGLUT.git", from: "1.0.1"), .package(url: "https://github.com/BradLarson/CVideo4Linux.git", from: "1.0.2")]
let platformExcludes =  ["iOS", "Mac", "Operations/Shaders", "Linux/RPiRenderWindow.swift", "Linux/OpenGLContext-RPi.swift", "Linux/V4LSupplement"]
#endif


let package = Package(
    name: "GPUImage",
    products: [
        .library(
            name: "GPUImage",
            targets: ["GPUImage"]),
    ],
    dependencies: platformDepedencies,
    targets: [
        .target(
            name: "GPUImage",
            path: "framework/Source",
            exclude: platformExcludes),
    ]
)
