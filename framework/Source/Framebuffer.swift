#if os(Linux)
import Glibc
#endif

#if canImport(OpenGL)
import OpenGL.GL3
#endif

#if canImport(OpenGLES)
import OpenGLES
#endif

#if canImport(COpenGLES)
import COpenGLES.gles2
let GL_BGRA = GL_RGBA // A hack: Raspberry Pi needs this or framebuffer creation fails
#endif

#if canImport(COpenGL)
import COpenGL
#endif

import Foundation

// TODO: Add a good lookup table to this to allow for detailed error messages
struct FramebufferCreationError:Error {
    let errorCode:GLenum
}

public enum FramebufferTimingStyle {
    case stillImage
    case videoFrame(timestamp:Timestamp)
    
    func isTransient() -> Bool {
        switch self {
            case .stillImage: return false
            case .videoFrame: return true
        }
    }
    
    var timestamp:Timestamp? {
        get {
            switch self {
                case .stillImage: return nil
                case let .videoFrame(timestamp): return timestamp
            }
        }
    }
}

public class Framebuffer {
    public var timingStyle:FramebufferTimingStyle = .stillImage
    public var orientation:ImageOrientation

    public let texture:GLuint
    let framebuffer:GLuint?
    let stencilBuffer:GLuint?
    public let size:GLSize
    let internalFormat:Int32
    let format:Int32
    let type:Int32

    let hash:Int64
    let textureOverride:Bool
    
    weak var context:OpenGLContext?
    
    public init(context:OpenGLContext, orientation:ImageOrientation, size:GLSize, textureOnly:Bool = false, minFilter:Int32 = GL_LINEAR, magFilter:Int32 = GL_LINEAR, wrapS:Int32 = GL_CLAMP_TO_EDGE, wrapT:Int32 = GL_CLAMP_TO_EDGE, internalFormat:Int32 = GL_RGBA, format:Int32 = GL_BGRA, type:Int32 = GL_UNSIGNED_BYTE, stencil:Bool = false, overriddenTexture:GLuint? = nil) throws {
        self.context = context
        self.size = size
        self.orientation = orientation
        self.internalFormat = internalFormat
        self.format = format
        self.type = type
        
        self.hash = hashForFramebufferWithProperties(orientation:orientation, size:size, textureOnly:textureOnly, minFilter:minFilter, magFilter:magFilter, wrapS:wrapS, wrapT:wrapT, internalFormat:internalFormat, format:format, type:type, stencil:stencil)

        if let newTexture = overriddenTexture {
            textureOverride = true
            texture = newTexture
        } else {
            textureOverride = false
            texture = generateTexture(minFilter:minFilter, magFilter:magFilter, wrapS:wrapS, wrapT:wrapT)
        }
        
        if (!textureOnly) {
            do {
                let (createdFrameBuffer, createdStencil) = try generateFramebufferForTexture(texture, width:size.width, height:size.height, internalFormat:internalFormat, format:format, type:type, stencil:stencil)
                framebuffer = createdFrameBuffer
                stencilBuffer = createdStencil
            } catch {
                stencilBuffer = nil
                framebuffer = nil
                throw error
            }
        } else {
            stencilBuffer = nil
            framebuffer = nil
        }
    }
    
    deinit {
        if (!textureOverride) {
            var mutableTexture = texture
            glDeleteTextures(1, &mutableTexture)
            debugPrint("Delete texture at size: \(size)")
        }
        
        if let framebuffer = framebuffer {
			var mutableFramebuffer = framebuffer
            glDeleteFramebuffers(1, &mutableFramebuffer)
        }

        if let stencilBuffer = stencilBuffer {
            var mutableStencil = stencilBuffer
            glDeleteRenderbuffers(1, &mutableStencil)
        }
    }
    
    public func sizeForTargetOrientation(_ targetOrientation:ImageOrientation) -> GLSize {
        if self.orientation.rotationNeededForOrientation(targetOrientation).flipsDimensions() {
            return GLSize(width:size.height, height:size.width)
        } else {
            return size
        }
    }
    
    public func aspectRatioForRotation(_ rotation:Rotation) -> Float {
        if rotation.flipsDimensions() {
            return Float(size.width) / Float(size.height)
        } else {
            return Float(size.height) / Float(size.width)
        }
    }

    public func texelSize(for rotation:Rotation) -> Size {
        if rotation.flipsDimensions() {
            return Size(width:1.0 / Float(size.height), height:1.0 / Float(size.width))
        } else {
            return Size(width:1.0 / Float(size.width), height:1.0 / Float(size.height))
        }
    }

    func initialStageTexelSize(for rotation:Rotation) -> Size {
        if rotation.flipsDimensions() {
            return Size(width:1.0 / Float(size.height), height:0.0)
        } else {
            return Size(width:0.0, height:1.0 / Float(size.height))
        }
    }

    public func texturePropertiesForOutputRotation(_ rotation:Rotation) -> InputTextureProperties {
        return InputTextureProperties(textureVBO:context!.textureVBO(for:rotation), texture:texture)
    }

    public func texturePropertiesForTargetOrientation(_ targetOrientation:ImageOrientation) -> InputTextureProperties {
        return texturePropertiesForOutputRotation(self.orientation.rotationNeededForOrientation(targetOrientation))
    }
    
    public func activateFramebufferForRendering() {
        guard let framebuffer = framebuffer else { fatalError("ERROR: Attempted to activate a framebuffer that has not been initialized") }
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glViewport(0, 0, size.width, size.height)
    }
    
    // MARK: -
    // MARK: Framebuffer cache

    weak var cache:FramebufferCache?
    var framebufferRetainCount = 0
    public func lock() {
        framebufferRetainCount += 1
    }

    func resetRetainCount() {
        framebufferRetainCount = 0
    }
    
    public func unlock() {
        framebufferRetainCount -= 1
        if (framebufferRetainCount < 1) {
            if ((framebufferRetainCount < 0) && (cache != nil)) {
                print("WARNING: Tried to overrelease a framebuffer")
            }
            framebufferRetainCount = 0
            cache?.returnToCache(self)
        }
    }
}

func hashForFramebufferWithProperties(orientation:ImageOrientation, size:GLSize, textureOnly:Bool = false, minFilter:Int32 = GL_LINEAR, magFilter:Int32 = GL_LINEAR, wrapS:Int32 = GL_CLAMP_TO_EDGE, wrapT:Int32 = GL_CLAMP_TO_EDGE, internalFormat:Int32 = GL_RGBA, format:Int32 = GL_BGRA, type:Int32 = GL_UNSIGNED_BYTE, stencil:Bool = false) -> Int64 {
    var result:Int64 = 1
    let prime:Int64 = 31
    let yesPrime:Int64 = 1231
    let noPrime:Int64 = 1237
    
    // TODO: Complete the rest of this
    result = prime * result + Int64(size.width)
    result = prime * result + Int64(size.height)
    result = prime * result + Int64(internalFormat)
    result = prime * result + Int64(format)
    result = prime * result + Int64(type)
    result = prime * result + (textureOnly ? yesPrime : noPrime)
    result = prime * result + (stencil ? yesPrime : noPrime)
    return result
}

// MARK: -
// MARK: Framebuffer-related extensions

extension Rotation {
    func textureCoordinates() -> [GLfloat] {
        switch self {
            case .noRotation: return [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0]
            case .rotateCounterclockwise: return [0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0]
            case .rotateClockwise: return [1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0]
            case .rotate180: return [1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0]
            case .flipHorizontally: return [1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0]
            case .flipVertically: return [0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0]
            case .rotateClockwiseAndFlipVertically: return [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0]
            case .rotateClockwiseAndFlipHorizontally: return [1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]
        }
    }
    
    func croppedTextureCoordinates(offsetFromOrigin:Position, cropSize:Size) -> [GLfloat] {
        let minX = GLfloat(offsetFromOrigin.x)
        let minY = GLfloat(offsetFromOrigin.y)
        let maxX = GLfloat(offsetFromOrigin.x) + GLfloat(cropSize.width)
        let maxY = GLfloat(offsetFromOrigin.y) + GLfloat(cropSize.height)

        switch self {
            case .noRotation: return [minX, minY, maxX, minY, minX, maxY, maxX, maxY]
            case .rotateCounterclockwise: return [minX, maxY, minX, minY, maxX, maxY, maxX, minY]
            case .rotateClockwise: return [maxX, minY, maxX, maxY, minX, minY, minX, maxY]
            case .rotate180: return [maxX, maxY, minX, maxY, maxX, minY, minX, minY]
            case .flipHorizontally: return [maxX, minY, minX, minY, maxX, maxY, minX, maxY]
            case .flipVertically: return [minX, maxY, maxX, maxY, minX, minY, maxX, minY]
            case .rotateClockwiseAndFlipVertically: return [minX, minY, minX, maxY, maxX, minY, maxX, maxY]
            case .rotateClockwiseAndFlipHorizontally: return [maxX, maxY, maxX, minY, minX, maxY, minX, minY]
        }
    }
}

public extension Size {
    func glWidth() -> GLint {
        return GLint(round(Double(self.width)))
    }

    func glHeight() -> GLint {
        return GLint(round(Double(self.height)))
    }
}
