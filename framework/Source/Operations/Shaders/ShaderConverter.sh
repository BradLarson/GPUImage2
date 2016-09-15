#!/usr/bin/swift

// This converts shader files into Swift inlined strings for embedding in the library
import Foundation

enum OpenGLPlatform {
    case OpenGL
    case OpenGLES
    case Both
}

let fileNames = CommandLine.arguments.dropFirst()

var allConvertedGLShaders = ""
var allConvertedGLESShaders = ""

for fileName in fileNames {
    let pathURL = URL(fileURLWithPath:fileName)
    let pathExtension = pathURL.pathExtension
    let baseName = pathURL.deletingPathExtension().lastPathComponent
    
    guard (FileManager.default.fileExists(atPath:pathURL.path)) else {
        print("Error: file \"\(fileName)\" could not be found.")
        continue
    }
    
    let shaderSuffix:String
    if (pathExtension.lowercased() == "vsh") {
        shaderSuffix = "VertexShader"
    } else if (pathExtension.lowercased() == "fsh") {
        shaderSuffix = "FragmentShader"
    } else {
        continue
    }
    
    let convertedShaderName:String
    let shaderPlatform:OpenGLPlatform
    if baseName.hasSuffix("_GLES") {
        convertedShaderName = "\(baseName.replacingOccurrences(of:"_GLES", with:""))\(shaderSuffix)"
        shaderPlatform = .OpenGLES
    } else if baseName.hasSuffix("_GL") {
        convertedShaderName = "\(baseName.replacingOccurrences(of:"_GL", with:""))\(shaderSuffix)"
        shaderPlatform = .OpenGL
    } else {
        convertedShaderName = "\(baseName)\(shaderSuffix)"
        shaderPlatform = .Both
    }
    
    var accumulatedString = "public let \(convertedShaderName) = \""
    let fileContents = try String(contentsOfFile:fileName, encoding:String.Encoding.ascii)
    fileContents.enumerateLines {line, stop in
        accumulatedString += "\(line.replacingOccurrences(of:"\"", with:"\\\""))\\n "
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

let scriptURL = URL(fileURLWithPath:CommandLine.arguments.first!)
try allConvertedGLShaders.write(to:scriptURL.deletingLastPathComponent().appendingPathComponent("ConvertedShaders_GL.swift"), atomically:true, encoding:String.Encoding.ascii)
try allConvertedGLESShaders.write(to:scriptURL.deletingLastPathComponent().appendingPathComponent("ConvertedShaders_GLES.swift"), atomically:true, encoding:String.Encoding.ascii)
