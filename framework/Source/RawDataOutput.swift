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

open class RawDataOutput: ImageConsumer {
    open var dataAvailableCallback:(([UInt8]) -> ())?
    
    open let sources = SourceContainer()
    open let maximumInputs:UInt = 1

    public init() {
    }

    // TODO: Replace with texture caches
    open func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(framebuffer.orientation, size:framebuffer.size)
        renderFramebuffer.lock()

        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.black)
        renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:ShaderUniformSettings(), vertices:standardImageVertices, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.noRotation)])
        framebuffer.unlock()
        
        var data = [UInt8](repeating:0, count:Int(framebuffer.size.width * framebuffer.size.height * 4))
        glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &data)
        renderFramebuffer.unlock()

        dataAvailableCallback?(data)
    }
}
