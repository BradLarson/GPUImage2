import COpenGL
import Dispatch

public class OpenGLContext: SerialDispatch {
    public lazy var framebufferCache:FramebufferCache = {
        return FramebufferCache(context:self)
    }()
    var shaderCache:[String:ShaderProgram] = [:]
    public let standardImageVBO:GLuint
    var textureVBOs:[Rotation:GLuint] = [:]
        
    public let serialDispatchQueue:DispatchQueue = DispatchQueue(label:"com.sunsetlakesoftware.GPUImage.processingQueue", attributes: [])
    public let dispatchQueueKey = DispatchSpecificKey<Int>()

    lazy var passthroughShader:ShaderProgram = {
        return crashOnShaderCompileFailure("OpenGLContext"){return try self.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()
	
    // MARK: -
    // MARK: Initialization and teardown

    init() {
        serialDispatchQueue.setSpecific(key:dispatchQueueKey, value:81)

        standardImageVBO = generateVBO(for:standardImageVertices)
        generateTextureVBOs()

        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
    
    // MARK: -
    // MARK: Rendering
    
    public func makeCurrentContext() {
    }
    
    func presentBufferForDisplay() {
    }
    
    // MARK: -
    // MARK: Device capabilities

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
//            return String.fromCString(UnsafePointer<CChar>(glGetString(GLenum(GL_EXTENSIONS))))!
        }
    }()
}
