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
    
import Foundation


struct ShaderCompileError:Error {
    let compileLog:String
}

enum ShaderType {
    case vertex
    case fragment
}

public class ShaderProgram {
    public var colorUniformsUseFourComponents = false
    let program:GLuint
    var vertexShader:GLuint! // At some point, the Swift compiler will be able to deal with the early throw and we can convert these to lets
    var fragmentShader:GLuint!
    private var attributeAddresses = [String:GLuint]()
    private var uniformAddresses = [String:GLint]()
    private var currentUniformIntValues = [String:GLint]()
    private var currentUniformFloatValues = [String:GLfloat]()
    private var currentUniformFloatArrayValues = [String:[GLfloat]]()
    
    // MARK: -
    // MARK: Initialization and teardown
    
    public init(vertexShader:String, fragmentShader:String) throws {
        program = glCreateProgram()
        
        self.vertexShader = try compileShader(vertexShader, type:.vertex)
        self.fragmentShader = try compileShader(fragmentShader, type:.fragment)
        
        glAttachShader(program, self.vertexShader)
        glAttachShader(program, self.fragmentShader)
        
        try link()
    }

    public convenience init(vertexShader:String, fragmentShaderFile:URL) throws {
        try self.init(vertexShader:vertexShader, fragmentShader:try shaderFromFile(fragmentShaderFile))
    }

    public convenience init(vertexShaderFile:URL, fragmentShaderFile:URL) throws {
        try self.init(vertexShader:try shaderFromFile(vertexShaderFile), fragmentShader:try shaderFromFile(fragmentShaderFile))
    }
    
    deinit {
        debugPrint("Shader deallocated")

        if (vertexShader != nil) {
            glDeleteShader(vertexShader)
        }
        if (fragmentShader != nil) {
            glDeleteShader(fragmentShader)
        }
        glDeleteProgram(program)
    }
    
    // MARK: -
    // MARK: Attributes and uniforms
    
    public func attributeIndex(_ attribute:String) -> GLuint? {
        if let attributeAddress = attributeAddresses[attribute] {
            return attributeAddress
        } else {
            var attributeAddress:GLint = -1
            attribute.withGLChar{glString in
                attributeAddress = glGetAttribLocation(self.program, glString)
            }

            if (attributeAddress < 0) {
                return nil
            } else {
                glEnableVertexAttribArray(GLuint(attributeAddress))
                attributeAddresses[attribute] = GLuint(attributeAddress)
                return GLuint(attributeAddress)
            }
        }
    }
    
    public func uniformIndex(_ uniform:String) -> GLint? {
        if let uniformAddress = uniformAddresses[uniform] {
            return uniformAddress
        } else {
            var uniformAddress:GLint = -1
            uniform.withGLChar{glString in
                uniformAddress = glGetUniformLocation(self.program, glString)
            }

            if (uniformAddress < 0) {
                return nil
            } else {
                uniformAddresses[uniform] = uniformAddress
                return uniformAddress
            }
        }
    }
    
    // MARK: -
    // MARK: Uniform accessors
    
    public func setValue(_ value:GLfloat, forUniform:String) {
        guard let uniformAddress = uniformIndex(forUniform) else {
            debugPrint("Warning: Tried to set a uniform (\(forUniform)) that was missing or optimized out by the compiler")
            return
        }
        if (currentUniformFloatValues[forUniform] != value) {
            glUniform1f(GLint(uniformAddress), value)
            currentUniformFloatValues[forUniform] = value
        }
    }

    public func setValue(_ value:GLint, forUniform:String) {
        guard let uniformAddress = uniformIndex(forUniform) else {
            debugPrint("Warning: Tried to set a uniform (\(forUniform)) that was missing or optimized out by the compiler")
            return
        }
        if (currentUniformIntValues[forUniform] != value) {
            glUniform1i(GLint(uniformAddress), value)
            currentUniformIntValues[forUniform] = value
        }
    }

    public func setValue(_ value:Color, forUniform:String) {
        if colorUniformsUseFourComponents {
            self.setValue(value.toGLArrayWithAlpha(), forUniform:forUniform)
        } else {
            self.setValue(value.toGLArray(), forUniform:forUniform)
        }
    }
    
    public func setValue(_ value:[GLfloat], forUniform:String) {
        guard let uniformAddress = uniformIndex(forUniform) else {
            debugPrint("Warning: Tried to set a uniform (\(forUniform)) that was missing or optimized out by the compiler")
            return
        }
        if let previousValue = currentUniformFloatArrayValues[forUniform], previousValue == value{
        } else {
            if (value.count == 2) {
                glUniform2fv(uniformAddress, 1, value)
            } else if (value.count == 3) {
                glUniform3fv(uniformAddress, 1, value)
            } else if (value.count == 4) {
                glUniform4fv(uniformAddress, 1, value)
            } else {
                fatalError("Tried to set a float array uniform outside of the range of values")
            }
            currentUniformFloatArrayValues[forUniform] = value
        }
    }

    public func setMatrix(_ value:[GLfloat], forUniform:String) {
        guard let uniformAddress = uniformIndex(forUniform) else {
            debugPrint("Warning: Tried to set a uniform (\(forUniform)) that was missing or optimized out by the compiler")
            return
        }
        if let previousValue = currentUniformFloatArrayValues[forUniform], previousValue == value{
        } else {
            if (value.count == 9) {
                glUniformMatrix3fv(uniformAddress, 1, GLboolean(GL_FALSE), value)
            } else if (value.count == 16) {
                glUniformMatrix4fv(uniformAddress, 1, GLboolean(GL_FALSE), value)
            } else {
                fatalError("Tried to set a matrix uniform outside of the range of supported sizes (3x3, 4x4)")
            }
            currentUniformFloatArrayValues[forUniform] = value
        }
    }

    // MARK: -
    // MARK: Usage
    
    func link() throws {
        glLinkProgram(program)
        
        var linkStatus:GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkStatus)
        if (linkStatus == 0) {
            var logLength:GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if (logLength > 0) {
                var compileLog = [CChar](repeating:0, count:Int(logLength))
                
                glGetProgramInfoLog(program, logLength, &logLength, &compileLog)
                print("Link log: \(String(cString:compileLog))")
            }
            
            throw ShaderCompileError(compileLog:"Link error")
        }
    }
    
    public func use() {
        glUseProgram(program)
    }
}

func compileShader(_ shaderString:String, type:ShaderType) throws -> GLuint {
    let shaderHandle:GLuint
    switch type {
        case .vertex: shaderHandle = glCreateShader(GLenum(GL_VERTEX_SHADER))
        case .fragment: shaderHandle = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
    }
    
    shaderString.withGLChar{glString in
        var tempString:UnsafePointer<GLchar>? = glString
        glShaderSource(shaderHandle, 1, &tempString, nil)
        glCompileShader(shaderHandle)
    }
    
    var compileStatus:GLint = 1
    glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileStatus)
    if (compileStatus != 1) {
        var logLength:GLint = 0
        glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if (logLength > 0) {
            var compileLog = [CChar](repeating:0, count:Int(logLength))
            
            glGetShaderInfoLog(shaderHandle, logLength, &logLength, &compileLog)
            print("Compile log: \(String(cString:compileLog))")
            // let compileLogString = String(bytes:compileLog.map{UInt8($0)}, encoding:NSASCIIStringEncoding)
            
            switch type {
                case .vertex: throw ShaderCompileError(compileLog:"Vertex shader compile error:")
                case .fragment: throw ShaderCompileError(compileLog:"Fragment shader compile error:")
            }
        }
    }
    
    return shaderHandle
}

public func crashOnShaderCompileFailure<T>(_ shaderName:String, _ operation:() throws -> T) -> T {
    do {
        return try operation()
    } catch {
        print("ERROR: \(shaderName) compilation failed with error: \(error)")
        fatalError("Aborting execution.")
    }
}

public func shaderFromFile(_ file:URL) throws -> String {
    // Note: this is a hack until Foundation's String initializers are fully functional
    //        let fragmentShaderString = String(contentsOfURL:fragmentShaderFile, encoding:NSASCIIStringEncoding)
    guard (FileManager.default.fileExists(atPath: file.path)) else { throw ShaderCompileError(compileLog:"Shader file \(file) missing")}

    let fragmentShaderString = try NSString(contentsOfFile:file.path, encoding:String.Encoding.ascii.rawValue)
    
    return String(describing:fragmentShaderString)
}
