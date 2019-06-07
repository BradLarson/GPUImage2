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
