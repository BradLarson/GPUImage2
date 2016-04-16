# CFreeGLUT

This is a simple module map for the freeglut library, most likely to be used for Linux. I've used this in a couple of projects in Ubuntu 14.04.

To use, have something like the following in your application's Package.swift:

```
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/BradLarson/CFreeGLUT.git", majorVersion: 1)
    ]
)
```

or clone this locally and use

```
swiftc -I ./CFreeGLUT myfile.swift
```

or the like to pull it in.

Then you just need an

```
import CFreeGLUT
```

in your Swift code to import the freeglut functions.