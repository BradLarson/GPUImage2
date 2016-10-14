import COpenGLES.gles2
import CVideoCore

public class OpenGLContext: SerialDispatch {
    lazy var framebufferCache:FramebufferCache = {
        return FramebufferCache(context:self)
    }()
    var shaderCache:[String:ShaderProgram] = [:]
    
    lazy var passthroughShader:ShaderProgram = {
        return crashOnShaderCompileFailure("OpenGLContext"){return try self.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()
	
    // MARK: -
    // MARK: Initialization and teardown

    init() {
	    bcm_host_init()
        
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
    
    // MARK: -
    // MARK: Rendering
    
    func makeCurrentContext() {
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
        }
    }()
}