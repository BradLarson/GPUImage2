#if canImport(OpenGLES)

import OpenGLES
import UIKit

// TODO: Find a way to warn people if they set this after the context has been created
var imageProcessingShareGroup:EAGLSharegroup? = nil

public class OpenGLContext: SerialDispatch {
    lazy var framebufferCache:FramebufferCache = {
        return FramebufferCache(context:self)
    }()
    var shaderCache:[String:ShaderProgram] = [:]
    public let standardImageVBO:GLuint
    var textureVBOs:[Rotation:GLuint] = [:]

    let context:EAGLContext
    
    lazy var passthroughShader:ShaderProgram = {
        return crashOnShaderCompileFailure("OpenGLContext"){return try self.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()

    lazy var coreVideoTextureCache:CVOpenGLESTextureCache = {
        var newTextureCache:CVOpenGLESTextureCache? = nil
        let err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, self.context, nil, &newTextureCache)
        return newTextureCache!
    }()
    
    
    public let serialDispatchQueue:DispatchQueue = DispatchQueue(label:"com.sunsetlakesoftware.GPUImage.processingQueue", attributes: [])
    public let dispatchQueueKey = DispatchSpecificKey<Int>()
    
    // MARK: -
    // MARK: Initialization and teardown

    init() {
        serialDispatchQueue.setSpecific(key:dispatchQueueKey, value:81)
        
        let generatedContext:EAGLContext?
        if let shareGroup = imageProcessingShareGroup {
            generatedContext = EAGLContext(api:.openGLES2, sharegroup:shareGroup)
        } else {
            generatedContext = EAGLContext(api:.openGLES2)
        }
        
        guard let concreteGeneratedContext = generatedContext else {
            fatalError("Unable to create an OpenGL ES 2.0 context. The GPUImage framework requires OpenGL ES 2.0 support to work.")
        }
        
        self.context = concreteGeneratedContext
        EAGLContext.setCurrent(concreteGeneratedContext)
        
        standardImageVBO = generateVBO(for:standardImageVertices)
        generateTextureVBOs()

        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
    
    // MARK: -
    // MARK: Rendering
    
    public func makeCurrentContext() {
        if (EAGLContext.current() != self.context)
        {
            EAGLContext.setCurrent(self.context)
        }
    }
    
    func presentBufferForDisplay() {
        self.context.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    
    // MARK: -
    // MARK: Device capabilities
    
    func supportsTextureCaches() -> Bool {
#if targetEnvironment(simulator)
        return false // Simulator glitches out on use of texture caches
#else
        return true // Every iOS version and device that can run Swift can handle texture caches
#endif
    }
    
    public var maximumTextureSizeForThisDevice:GLint {get { return _maximumTextureSizeForThisDevice } }
    private lazy var _maximumTextureSizeForThisDevice:GLint = {
        return self.openGLDeviceSettingForOption(GL_MAX_TEXTURE_SIZE)
    }()

    public var maximumTextureUnitsForThisDevice:GLint {get { return _maximumTextureUnitsForThisDevice } }
    private lazy var _maximumTextureUnitsForThisDevice:GLint = {
        return self.openGLDeviceSettingForOption(GL_MAX_TEXTURE_IMAGE_UNITS)
    }()

    public var maximumVaryingVectorsForThisDevice:GLint {get { return _maximumVaryingVectorsForThisDevice } }
    private lazy var _maximumVaryingVectorsForThisDevice:GLint = {
        return self.openGLDeviceSettingForOption(GL_MAX_VARYING_VECTORS)
    }()

    lazy var extensionString:String = {
        return self.runOperationSynchronously{
            self.makeCurrentContext()
            return String(cString:unsafeBitCast(glGetString(GLenum(GL_EXTENSIONS)), to:UnsafePointer<CChar>.self))
        }
    }()
}
#endif
