// swift-tools-version:4.2

import PackageDescription

#if os(macOS) // This fires for both macOS and iOS targets, because it's based on build platform
let platformDependencies: [Package.Dependency] = []
let platformExcludes = ["Linux", "Operations/Shaders"]
let platformTargets: [Target] = [
        .target(
            name: "GPUImage",
            path: "framework/Source",
            exclude: platformExcludes)]
let platformProducts: [Product] =  [
        .library(
            name: "GPUImage",
            targets: ["GPUImage"]),
    ]
#elseif os(Linux)
// TODO: Add back in RPi support
// TODO: Move the remote system library packages into this project
let platformDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.0.0"),
    .package(url: "https://github.com/BradLarson/COpenGL.git", from: "1.0.2"), 
    .package(url: "https://github.com/BradLarson/CFreeGLUT.git", from: "1.0.1"), 
    .package(url: "https://github.com/BradLarson/CVideo4Linux.git", from: "1.0.2")]
let platformExcludes =  ["Apple", "Operations/Shaders", "Linux/RPiRenderWindow.swift", "Linux/OpenGLContext-RPi.swift", "Linux/V4LSupplement", "Linux/V4LCamera"]
let platformTargets: [Target] = [
        // .target(
        //     name: "lodepng",
        //     path: "framework/Packages/lodepng"),
        .target(
            name: "GPUImage",
            dependencies: ["SwiftGD"],
            path: "framework/Source",
            exclude: platformExcludes),
        .target(
            name: "V4LSupplement",
            path: "framework/Source/Linux/V4LSupplement"),
        .target(
            name: "GPUImageV4LCamera",
            dependencies: ["GPUImage", "V4LSupplement"],
            path: "framework/Source/Linux/V4LCamera")]
let platformProducts: [Product] =  [
        .library(
            name: "GPUImage",
            targets: ["GPUImage"]),
        .library(
            name: "GPUImageV4LCamera",
            targets: ["GPUImageV4LCamera"]),
    ]
#endif


let package = Package(
    name: "GPUImage",
    products: platformProducts,
    dependencies: platformDependencies,
    targets: platformTargets,
    swiftLanguageVersions: [.v4]
)
