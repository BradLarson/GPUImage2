#if os(Linux)
import Glibc
#endif

import Foundation

public class MotionBlur: BasicOperation {
    public var blurSize:Float = 2.5
    public var blurAngle:Float = 0.0
    
    public init() {
        super.init(vertexShader:MotionBlurVertexShader, fragmentShader:MotionBlurFragmentShader, numberOfInputs:1)
    }
    
    override func configureFramebufferSpecificUniforms(_ inputFramebuffer:Framebuffer) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.portrait)
        let texelSize = inputFramebuffer.texelSize(for:outputRotation)
        
        let aspectRatio = inputFramebuffer.aspectRatioForRotation(outputRotation)
        let directionalTexelStep:Position
        if outputRotation.flipsDimensions() {
            let xOffset = blurSize * Float(sin(Double(blurAngle) * .pi / 180.0)) * aspectRatio * texelSize.width
            let yOffset = blurSize * Float(cos(Double(blurAngle) * .pi / 180.0)) * texelSize.width
            directionalTexelStep = Position(xOffset, yOffset)
        } else {
            let xOffset = blurSize * Float(cos(Double(blurAngle) * .pi / 180.0)) * aspectRatio * texelSize.width
            let yOffset = blurSize * Float(sin(Double(blurAngle) * .pi / 180.0)) * texelSize.width
            directionalTexelStep = Position(xOffset, yOffset)
        }
        
        uniformSettings["directionalTexelStep"] = directionalTexelStep
    }
}
