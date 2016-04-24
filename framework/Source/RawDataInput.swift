#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL3
#endif
#endif

public enum PixelFormat {
    case BGRA
    case RGBA
    case RGB
    case Luminance
    
    func toGL() -> Int32 {
        switch self {
            case .BGRA: return GL_BGRA
            case .RGBA: return GL_RGBA
            case .RGB: return GL_RGB
            case .Luminance: return GL_LUMINANCE
        }
    }
}

// TODO: Replace with texture caches where appropriate
public class RawDataInput: ImageSource {
    public let targets = TargetContainer()
    
    public init() {
        
    }

    public func uploadBytes(bytes:[UInt8], size:Size, pixelFormat:PixelFormat, orientation:ImageOrientation = .Portrait) {
        let dataFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:orientation, size:GLSize(size), textureOnly:true, internalFormat:pixelFormat.toGL(), format:pixelFormat.toGL())

        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), dataFramebuffer.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, size.glWidth(), size.glHeight(), 0, GLenum(pixelFormat.toGL()), GLenum(GL_UNSIGNED_BYTE), bytes)

        updateTargetsWithFramebuffer(dataFramebuffer)
    }
}