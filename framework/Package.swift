let package = Package(
  name: "GPUImage",
  targets: [
    Target(name: "GPUImage")
 ],
#if os(OSX)
  exclude: [
    "iOS",
    "Linux"
  ])
#elseif os(iOS)
  exclude: [
    "Linux",
    "Mac"
  ])
#elseif os(Linux)
    dependencies: [
        .Package(url: "./Packages/CVideo4Linux",
                 majorVersion: 1),
        .Package(url: "./Packages/COpenGL",
                 majorVersion: 1),
        .Package(url: "./Packages/CFreeGLUT",
                 majorVersion: 1),
    ],
  exclude: [
    "iOS",
    "Mac"
  ])
#endif
  