import OpenGLES
import UIKit

// TODO: Find a way to warn people if they set this after the context has been created
var imageProcessingShareGroup:EAGLSharegroup? = nil

class OpenGLContext: SerialDispatch {
    lazy var framebufferCache:FramebufferCache = {
        return FramebufferCache(context:self)
    }()
    var shaderCache:[String:ShaderProgram] = [:]
    
    let context:EAGLContext
    
    lazy var passthroughShader:ShaderProgram = {
        return crashOnShaderCompileFailure("OpenGLContext"){return try self.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()

    lazy var coreVideoTextureCache:CVOpenGLESTextureCacheRef = {
        var newTextureCache:CVOpenGLESTextureCacheRef? = nil
        let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, self.context, nil, &newTextureCache)
        return newTextureCache!
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
        
        guard let generatedContext = EAGLContext(API:.OpenGLES2, sharegroup:imageProcessingShareGroup) else {
            fatalError("Unable to create an OpenGL ES 2.0 context. The GPUImage framework requires OpenGL ES 2.0 support to work.")
        }
        
        self.context = generatedContext
        self.makeCurrentContext()
        
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
    
    // MARK: -
    // MARK: Rendering
    
    func makeCurrentContext() {
        if (EAGLContext.currentContext() != self.context)
        {
            EAGLContext.setCurrentContext(self.context)
        }
    }
    
    func presentBufferForDisplay() {
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    
    // MARK: -
    // MARK: Device capabilities
    
    func supportsTextureCaches() -> Bool {
#if (arch(i386) || arch(x86_64)) && os(iOS)
        return false // Simulator glitches out on use of texture caches
#else
        return true // Every iOS version and device that can run Swift can handle texture caches
#endif
    }
}