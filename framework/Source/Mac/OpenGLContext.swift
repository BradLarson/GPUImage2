import OpenGL.GL3
import Cocoa

// TODO: Figure out way to allow for multiple contexts for different GPUs

class OpenGLContext: SerialDispatch {
    lazy var framebufferCache:FramebufferCache = {
        return FramebufferCache(context:self)
    }()
    var shaderCache:[String:ShaderProgram] = [:]
    
    let context:NSOpenGLContext
    
    lazy var passthroughShader:ShaderProgram = {
        return crashOnShaderCompileFailure("OpenGLContext"){return try self.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()

    let serialDispatchQueue:dispatch_queue_t = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.processingQueue", nil)
    var dispatchKey:Int = 1
    let dispatchQueueKey:UnsafePointer<Void>

    // MARK: -
    // MARK: Initialization and teardown

    init() {
        let context = UnsafeMutablePointer<Void>(Unmanaged<dispatch_queue_t>.passUnretained(self.serialDispatchQueue).toOpaque())
        dispatchQueueKey = UnsafePointer<Void>(bitPattern:dispatchKey)
        dispatch_queue_set_specific(serialDispatchQueue, dispatchQueueKey, context, nil)

        let pixelFormatAttributes:[NSOpenGLPixelFormatAttribute] = [
            NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated), 0,
            0
        ]
        
        guard let pixelFormat = NSOpenGLPixelFormat(attributes:pixelFormatAttributes) else {
            fatalError("No appropriate pixel format found when creating OpenGL context.")
        }
        // TODO: Take into account the sharegroup
        guard let generatedContext = NSOpenGLContext(format:pixelFormat, shareContext:nil) else {
            fatalError("Unable to create an OpenGL context. The GPUImage framework requires OpenGL support to work.")
        }
        
        self.context = generatedContext
        self.context.makeCurrentContext()
        
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
    
    // MARK: -
    // MARK: Rendering
    
    func makeCurrentContext() {
        self.context.makeCurrentContext()
    }
    
    func presentBufferForDisplay() {
        self.context.flushBuffer()
    }    
}