import PackageDescription

/**
 Better to create variables for the excludes so you dont have the 
 package def wrapped with macros .

 Also need to trap if os is not support like watch and tv
*/
#if os(macOS)

let excludes = ["iOS", "Linux"]

#elseif os(iOS)

let excludes = ["Linux", "Mac"]

#elseif os(Linux)

let excludes =  ["iOS", "Mac"]

#endif


#if os(Linux) || os(macOS) || os(Linux)

let package = Package(
  name: "GPUImage",
  providers: [
		.Apt("libv4l-dev"), 
	],
  targets: [
    Target(name: "GPUImage")
 ],
  dependencies:[],
  exclude: excludes
  )
  
#if os(Linux)
   package.dependencies.append([
        .Package(url: "./Packages/CVideo4Linux", majorVersion: 1),
        .Package(url: "./Packages/COpenGL", majorVersion: 1),
        .Package(url: "./Packages/CFreeGLUT", majorVersion: 1),
    ])
#endif


#else
	
	fatalError("Unsupported OS")
	
#endif
