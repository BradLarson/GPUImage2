import Foundation

public class MotionBlur: BasicOperation {
    public var blurSize:Float = 2.5
    public var blurAngle:Float = 0.0
    
    public init() {
        super.init(vertexShader:MotionBlurVertexShader, fragmentShader:MotionBlurFragmentShader, numberOfInputs:1)
    }
    
    override func configureFramebufferSpecificUniforms(inputFramebuffer:Framebuffer) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.Portrait)
        let texelSize = inputFramebuffer.texelSizeForRotation(outputRotation)
        
        let aspectRatio = inputFramebuffer.aspectRatioForRotation(outputRotation)
        let directionalTexelStep:Position
        if outputRotation.flipsDimensions() {
            let xOffset = blurSize * sin(blurAngle * Float(M_PI) / 180.0) * aspectRatio * texelSize.width
            let yOffset = blurSize * cos(blurAngle * Float(M_PI) / 180.0) * texelSize.width
            directionalTexelStep = Position(xOffset, yOffset)
        } else {
            let xOffset = blurSize * cos(blurAngle * Float(M_PI) / 180.0) * aspectRatio * texelSize.width
            let yOffset = blurSize * sin(blurAngle * Float(M_PI) / 180.0) * texelSize.width
            directionalTexelStep = Position(xOffset, yOffset)
        }
        
        uniformSettings["directionalTexelStep"] = directionalTexelStep
    }
}
