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

open class TextureInput: ImageSource {
    open let targets = TargetContainer()
    
    let textureFramebuffer:Framebuffer

    public init(texture:GLuint, size:Size, orientation:ImageOrientation = .portrait) {
        do {
            textureFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:orientation, size:GLSize(size), textureOnly:true, overriddenTexture:texture)
        } catch {
            fatalError("Could not create framebuffer for custom input texture.")
        }
    }

    open func processTexture() {
        updateTargetsWithFramebuffer(textureFramebuffer)
    }
    
    open func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        textureFramebuffer.lock()
        target.newFramebufferAvailable(textureFramebuffer, fromSourceIndex:atIndex)
    }
}
