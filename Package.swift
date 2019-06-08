// swift-tools-version:4.2

import PackageDescription

#if os(macOS)
let platformDepedencies: [Package.Dependency] = []
let platformExcludes = ["iOS", "Linux", "Operations/Shaders"]
let platformTargets: [Target] = [
        .target(
            name: "GPUImage",
            path: "framework/Source",
            exclude: platformExcludes)]
#elseif os(iOS)
let platformDepedencies: [Package.Dependency] = []
let platformExcludes = ["Linux", "Mac", "Operations/Shaders"]
let platformTargets: [Target] = [
        .target(
            name: "GPUImage",
            path: "framework/Source",
            exclude: platformExcludes)]
#elseif os(Linux)
// TODO: Add back in RPi support
// TODO: Move the remote system library packages into this project
let platformDepedencies: [Package.Dependency] = [
    .package(url: "https://github.com/BradLarson/COpenGL.git", from: "1.0.2"), 
    .package(url: "https://github.com/BradLarson/CFreeGLUT.git", from: "1.0.1"), 
    .package(url: "https://github.com/BradLarson/CVideo4Linux.git", from: "1.0.2")]
let platformExcludes =  ["iOS", "Mac", "Operations/Shaders", "Linux/RPiRenderWindow.swift", "Linux/OpenGLContext-RPi.swift", "Linux/V4LSupplement"]
let platformTargets: [Target] = [
        .target(
            name: "V4LSupplement",
            path: "framework/Source/Linux/V4LSupplement"),
        .target(
            name: "GPUImage",
            dependencies: ["V4LSupplement"],
            path: "framework/Source",
            exclude: platformExcludes)]
#endif


let package = Package(
    name: "GPUImage",
    products: [
        .library(
            name: "GPUImage",
            targets: ["GPUImage"]),
    ],
    dependencies: platformDepedencies,
    targets: platformTargets,
    swiftLanguageVersions: [.v4]
)
