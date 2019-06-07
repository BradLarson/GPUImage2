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

public struct ShaderUniformSettings {
    private var uniformValues = [String:Any]()
    
    public init() {
    }

    public subscript(index:String) -> Float? {
        get { return uniformValues[index] as? Float}
        set(newValue) { uniformValues[index] = newValue }
    }
    
    public subscript(index:String) -> Int? {
        get { return uniformValues[index] as? Int }
        set(newValue) { uniformValues[index] = newValue }
    }

    public subscript(index:String) -> Color? {
        get { return uniformValues[index] as? Color }
        set(newValue) { uniformValues[index] = newValue }
    }

    public subscript(index:String) -> Position? {
        get { return uniformValues[index] as? Position }
        set(newValue) { uniformValues[index] = newValue }
    }

    public subscript(index:String) -> Size? {
        get { return uniformValues[index] as? Size}
        set(newValue) { uniformValues[index] = newValue }
    }

    public subscript(index:String) -> Matrix4x4? {
        get { return uniformValues[index] as? Matrix4x4 }
        set(newValue) { uniformValues[index] = newValue }
    }

    public subscript(index:String) -> Matrix3x3? {
        get { return uniformValues[index] as? Matrix3x3}
        set(newValue) { uniformValues[index] = newValue }
    }

    public func restoreShaderSettings(_ shader:ShaderProgram) {
        for (uniform, value) in uniformValues {
            switch value {
                case let value as Float: shader.setValue(GLfloat(value), forUniform:uniform)
                case let value as Int: shader.setValue(GLint(value), forUniform:uniform)
                case let value as Color: shader.setValue(value, forUniform:uniform)
                case let value as Position: shader.setValue(value.toGLArray(), forUniform:uniform)
                case let value as Size: shader.setValue(value.toGLArray(), forUniform:uniform)
                case let value as Matrix4x4: shader.setMatrix(value.toRowMajorGLArray(), forUniform:uniform)
                case let value as Matrix3x3: shader.setMatrix(value.toRowMajorGLArray(), forUniform:uniform)
                default: fatalError("Somehow tried to restore a shader uniform value of an unsupported type: \(value)")
            }
        }
    }
}

extension Color {
    func toGLArray() -> [GLfloat] {
        return [GLfloat(redComponent), GLfloat(greenComponent), GLfloat(blueComponent)]
    }

    func toGLArrayWithAlpha() -> [GLfloat] {
        return [GLfloat(redComponent), GLfloat(greenComponent), GLfloat(blueComponent), GLfloat(alphaComponent)]
    }
}

extension Position {
    func toGLArray() -> [GLfloat] {
        if let z = self.z {
            return [GLfloat(x), GLfloat(y), GLfloat(z)]
        } else {
            return [GLfloat(x), GLfloat(y)]
        }
    }
}

extension Size {
    func toGLArray() -> [GLfloat] {
        return [GLfloat(width), GLfloat(height)]
    }
}

extension Matrix4x4 {
    func toRowMajorGLArray() -> [GLfloat] {
        return [m11, m12, m13, m14,
                m21, m22, m23, m24,
                m31, m32, m33, m34,
                m41, m42, m43, m44]
    }
}

public extension Matrix3x3 {
    func toRowMajorGLArray() -> [GLfloat] {
        return [m11, m12, m13,
                m21, m22, m23,
                m31, m32, m33]
    }
}
