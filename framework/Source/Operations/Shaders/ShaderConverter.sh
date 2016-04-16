#!/usr/bin/swift

// This converts shader files into Swift inlined strings for embedding in the library
import Foundation

enum OpenGLPlatform {
	case OpenGL
	case OpenGLES
	case Both
}

let fileNames = Process.arguments.dropFirst()

var allConvertedGLShaders = ""
var allConvertedGLESShaders = ""

for fileName in fileNames {  
	let pathURL = NSURL(fileURLWithPath:fileName)
	guard let pathExtension = pathURL.pathExtension else {continue}
	guard let baseName = pathURL.URLByDeletingPathExtension?.lastPathComponent else {continue}
	
	guard (NSFileManager.defaultManager().fileExistsAtPath(pathURL.path!)) else {
		print("Error: file \"\(fileName)\" could not be found.")
		continue
	}
	
	let shaderSuffix:String
	if (pathExtension.lowercaseString == "vsh") {
		shaderSuffix = "VertexShader"
	} else if (pathExtension.lowercaseString == "fsh") {
		shaderSuffix = "FragmentShader"
	} else {
		continue
	}
	
	let convertedShaderName:String
	let shaderPlatform:OpenGLPlatform
	if baseName.hasSuffix("_GLES") {
		convertedShaderName = "\(baseName.stringByReplacingOccurrencesOfString("_GLES", withString:""))\(shaderSuffix)"
		shaderPlatform = .OpenGLES
	} else if baseName.hasSuffix("_GL") {
		convertedShaderName = "\(baseName.stringByReplacingOccurrencesOfString("_GL", withString:""))\(shaderSuffix)"
		shaderPlatform = .OpenGL
	} else {
		convertedShaderName = "\(baseName)\(shaderSuffix)"
		shaderPlatform = .Both
	}
	
	var accumulatedString = "public let \(convertedShaderName) = \""
	let fileContents = try String(contentsOfFile:fileName, encoding:NSASCIIStringEncoding)
  	fileContents.enumerateLines {line, stop in
		accumulatedString += "\(line.stringByReplacingOccurrencesOfString("\"", withString:"\\\""))\\n "
	}
  	accumulatedString += "\"\n"
	
	switch (shaderPlatform) {
		case .OpenGL: allConvertedGLShaders += accumulatedString
		case .OpenGLES: allConvertedGLESShaders += accumulatedString
		case .Both: 
			allConvertedGLShaders += accumulatedString
			allConvertedGLESShaders += accumulatedString
	}
}

let scriptURL = NSURL(fileURLWithPath:Process.arguments.first!)
try allConvertedGLShaders.writeToURL(scriptURL.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("ConvertedShaders_GL.swift"), atomically:true, encoding:NSASCIIStringEncoding)
try allConvertedGLESShaders.writeToURL(scriptURL.URLByDeletingLastPathComponent!.URLByAppendingPathComponent("ConvertedShaders_GLES.swift"), atomically:true, encoding:NSASCIIStringEncoding)
