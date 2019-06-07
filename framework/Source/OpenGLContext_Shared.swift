#if canImport(OpenGL)
import OpenGL.GL3
#endif

#if canImport(OpenGLES)
import OpenGLES
#endif

#if canImport(COpenGLES)
import COpenGLES.gles2
#endif

#if canImport(COpenGL)
import COpenGL
#endif


import Foundation

public let sharedImageProcessingContext = OpenGLContext()

extension OpenGLContext {
    public func programForVertexShader(_ vertexShader:String, fragmentShader:String) throws -> ShaderProgram {
        let lookupKeyForShaderProgram = "V: \(vertexShader) - F: \(fragmentShader)"
        if let shaderFromCache = shaderCache[lookupKeyForShaderProgram] {
            return shaderFromCache
        } else {
            return try sharedImageProcessingContext.runOperationSynchronously{
                let program = try ShaderProgram(vertexShader:vertexShader, fragmentShader:fragmentShader)
                self.shaderCache[lookupKeyForShaderProgram] = program
                return program
            }
        }
    }

    public func programForVertexShader(_ vertexShader:String, fragmentShader:URL) throws -> ShaderProgram {
        return try programForVertexShader(vertexShader, fragmentShader:try shaderFromFile(fragmentShader))
    }
    
    public func programForVertexShader(_ vertexShader:URL, fragmentShader:URL) throws -> ShaderProgram {
        return try programForVertexShader(try shaderFromFile(vertexShader), fragmentShader:try shaderFromFile(fragmentShader))
    }
    
    public func openGLDeviceSettingForOption(_ option:Int32) -> GLint {
        return self.runOperationSynchronously{() -> GLint in
            self.makeCurrentContext()
            var openGLValue:GLint = 0
            glGetIntegerv(GLenum(option), &openGLValue)
            return openGLValue
        }
    }
 
    public func deviceSupportsExtension(_ openGLExtension:String) -> Bool {
#if os(Linux)
        return false
#else
        return self.extensionString.contains(openGLExtension)
#endif
    }
    
    // http://www.khronos.org/registry/gles/extensions/EXT/EXT_texture_rg.txt
    
    public func deviceSupportsRedTextures() -> Bool {
        return deviceSupportsExtension("GL_EXT_texture_rg")
    }

    public func deviceSupportsFramebufferReads() -> Bool {
        return deviceSupportsExtension("GL_EXT_shader_framebuffer_fetch")
    }
    
    public func sizeThatFitsWithinATextureForSize(_ size:Size) -> Size {
        let maxTextureSize = Float(self.maximumTextureSizeForThisDevice)
        if ( (size.width < maxTextureSize) && (size.height < maxTextureSize) ) {
            return size
        }
        
        let adjustedSize:Size
        if (size.width > size.height) {
            adjustedSize = Size(width:maxTextureSize, height:(maxTextureSize / size.width) * size.height)
        } else {
            adjustedSize = Size(width:(maxTextureSize / size.height) * size.width, height:maxTextureSize)
        }
        
        return adjustedSize
    }
    
    func generateTextureVBOs() {
        textureVBOs[.noRotation] = generateVBO(for:Rotation.noRotation.textureCoordinates())
        textureVBOs[.rotateCounterclockwise] = generateVBO(for:Rotation.rotateCounterclockwise.textureCoordinates())
        textureVBOs[.rotateClockwise] = generateVBO(for:Rotation.rotateClockwise.textureCoordinates())
        textureVBOs[.rotate180] = generateVBO(for:Rotation.rotate180.textureCoordinates())
        textureVBOs[.flipHorizontally] = generateVBO(for:Rotation.flipHorizontally.textureCoordinates())
        textureVBOs[.flipVertically] = generateVBO(for:Rotation.flipVertically.textureCoordinates())
        textureVBOs[.rotateClockwiseAndFlipVertically] = generateVBO(for:Rotation.rotateClockwiseAndFlipVertically.textureCoordinates())
        textureVBOs[.rotateClockwiseAndFlipHorizontally] = generateVBO(for:Rotation.rotateClockwiseAndFlipHorizontally.textureCoordinates())
    }
    
    public func textureVBO(for rotation:Rotation) -> GLuint {
        guard let textureVBO = textureVBOs[rotation] else {fatalError("GPUImage doesn't have a texture VBO set for the rotation \(rotation)") }
        return textureVBO
    }
}

@_semantics("sil.optimize.never") public func debugPrint(_ stringToPrint:String, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
    #if DEBUG
        print("\(stringToPrint) --> \((String(describing:file) as NSString).lastPathComponent): \(function): \(line)")
    #endif
}
