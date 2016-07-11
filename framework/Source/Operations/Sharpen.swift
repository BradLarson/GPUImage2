public class Sharpen: BasicOperation {
    public var sharpness:Float = 0.0 { didSet { uniformSettings["sharpness"] = sharpness } }
    public var overriddenTexelSize:Size?
    
    public init() {
        super.init(vertexShader:SharpenVertexShader, fragmentShader:SharpenFragmentShader, numberOfInputs:1)
        
        ({sharpness = 0.0})()
    }
    
    override func configureFramebufferSpecificUniforms(_ inputFramebuffer:Framebuffer) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.portrait)
        let texelSize = overriddenTexelSize ?? inputFramebuffer.texelSize(for:outputRotation)
        uniformSettings["texelWidth"] = texelSize.width
        uniformSettings["texelHeight"] = texelSize.height
    }
}
