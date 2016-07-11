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

public class TextureInput: ImageSource {
    public let targets = TargetContainer()
    
    let textureFramebuffer:Framebuffer

    public init(texture:GLuint, size:Size, orientation:ImageOrientation = .portrait) {
        do {
            textureFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:orientation, size:GLSize(size), textureOnly:true, overriddenTexture:texture)
        } catch {
            fatalError("Could not create framebuffer for custom input texture.")
        }
    }

    public func processTexture() {
        updateTargetsWithFramebuffer(textureFramebuffer)
    }
    
    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        textureFramebuffer.lock()
        target.newFramebufferAvailable(textureFramebuffer, fromSourceIndex:atIndex)
    }
}
