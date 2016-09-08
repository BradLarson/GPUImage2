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

public class RawDataOutput: ImageConsumer {
    public var dataAvailableCallback:(([UInt8]) -> ())?
    
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1

    public init() {
    }

    // TODO: Replace with texture caches
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:framebuffer.size)
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
