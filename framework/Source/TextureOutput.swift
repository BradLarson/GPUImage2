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

public class TextureOutput: ImageConsumer {
    public var newTextureAvailableCallback:((GLuint) -> ())?
    
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        newTextureAvailableCallback?(framebuffer.texture)
        // TODO: Maybe extend the lifetime of the texture past this if needed
        framebuffer.unlock()
    }
}
