#!/usr/bin/swift

// This generates the compile scripts for the Linux targets
import Foundation

enum LinuxTarget {
    case OpenGL
    case RaspberryPi
    
    init?(_ argument:String) {
        switch argument {
            case "rpi", "RPi", "RPI": self = .RaspberryPi
            case "opengl", "gl", "GL", "OpenGL": self = .OpenGL
            default: return nil
        }
    }
	
	func compilerFlags() -> String {
		switch self {
			case .OpenGL: return "-DGL"
			case .RaspberryPi: return "-DGLES"
		}
	}

	func specificFiles() -> [String] {
		switch self {
			case .OpenGL: return ["Source/Linux/GLUTRenderWindow.swift", "Source/Linux/OpenGLContext.swift", "Source/Linux/V4LCamera.swift"]
			case .RaspberryPi: return ["Source/Linux/RPiRenderWindow.swift", "Source/Linux/OpenGLContext-RPi.swift", "Source/Linux/V4LCamera.swift"]
		}
	}

	func includes() -> [String] {
		switch self {
			case .OpenGL: return ["./Packages/COpenGL", "./Packages/CFreeGLUT", "./Packages/CVideo4Linux"]
			case .RaspberryPi: return ["./Packages/COpenGLES", "./Packages/CVideoCore", "./Packages/CVideo4Linux", "/opt/vc/include/", "/opt/vc/include/interface/vcos/pthreads/", "/opt/vc/include/interface/vmcs_host/linux/"]
		}
	}

	func linkLocations() -> [String] {
		switch self {
			case .OpenGL: return ["./"]
			case .RaspberryPi: return ["./", "/opt/vc/lib"]
		}
	}

	func shaderFile() -> String {
		switch self {
			case .OpenGL: return "./Source/Operations/Shaders/ConvertedShaders_GL.swift"
			case .RaspberryPi: return "./Source/Operations/Shaders/ConvertedShaders_GLES.swift"
		}
	}
	
}

func printWithPrefix(prefix:String, _ arguments:[String]) -> String {
    return prefix + arguments.joinWithSeparator(" \(prefix)")
}

func filenamesAtRelativePath(path:String) -> [String] {
    do {
        let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
        let swiftFiles = contents.filter{$0.hasSuffix(".swift")}.map{"\(path)/\($0)"}
		return swiftFiles
    } catch {
        print("Can't find directory: \(path) with error \(error)")
		exit(0)
    }
}

let baseDirectories = ["./Source", "./Source/Operations"]

// The executable portion of the script

guard (Process.arguments.count > 1) else { 
	print("Please specify a valid platform target: [rpi, opengl]")
	exit(0)
}

guard let target = LinuxTarget(Process.arguments[1]) else { 
	print("Please specify a valid platform target: [rpi, opengl]")
	exit(0)
}

let swiftFiles = baseDirectories.flatMap{filenamesAtRelativePath($0)} + [target.shaderFile()] + target.specificFiles()

// let operationNames = [target.shaderFile(), "./Source/Operations/SobelEdgeDetection.swift", "./Source/Operations/Pixellate.swift"]

// The actual lines of the compile script

let initialV4LSetupLine = "clang -fPIC -c ./Source/Linux/v4lfuncs.c -o v4lfuncs.o\n"

let moduleGenLine = "swiftc \(target.compilerFlags()) -module-name GPUImage -emit-module -import-objc-header ./Source/Linux/v4lfuncs.h \(printWithPrefix("-L ", target.linkLocations())) \(printWithPrefix("-I ", target.includes())) \(printWithPrefix("", swiftFiles)) \n"

let libraryGenLine = "swiftc \(target.compilerFlags()) -module-name GPUImage -import-objc-header ./Source/Linux/v4lfuncs.h \(printWithPrefix("-L ", target.linkLocations())) \(printWithPrefix("-I ", target.includes())) \(printWithPrefix("-c ", swiftFiles)) \n"

let linkerLine = "swiftc \(target.compilerFlags()) -module-name GPUImage -emit-library -import-objc-header ./Source/Linux/v4lfuncs.h \(printWithPrefix("-L ", target.linkLocations())) \(printWithPrefix("-I ", target.includes())) *.o \n"

let terminalLine = "rm *.o\n"

let completeScript = initialV4LSetupLine + moduleGenLine + libraryGenLine + linkerLine + terminalLine
print("\(completeScript)")