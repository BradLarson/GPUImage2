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

open class TextureOutput: ImageConsumer {
    open var newTextureAvailableCallback:((GLuint) -> ())?
    
    open let sources = SourceContainer()
    open let maximumInputs:UInt = 1
    
    open func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        newTextureAvailableCallback?(framebuffer.texture)
        // TODO: Maybe extend the lifetime of the texture past this if needed
        framebuffer.unlock()
    }
}
