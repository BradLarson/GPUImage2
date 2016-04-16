
let sharedImageProcessingContext = OpenGLContext()

extension OpenGLContext {
    func programForVertexShader(vertexShader:String, fragmentShader:String) throws -> ShaderProgram {
        let lookupKeyForShaderProgram = "V: \(vertexShader) - F: \(fragmentShader)"
        if let shaderFromCache = shaderCache[lookupKeyForShaderProgram] {
            return shaderFromCache
        } else {
            sharedImageProcessingContext.makeCurrentContext()
            let program = try ShaderProgram(vertexShader:vertexShader, fragmentShader:fragmentShader)
            shaderCache[lookupKeyForShaderProgram] = program
            return program
        }
    }
}