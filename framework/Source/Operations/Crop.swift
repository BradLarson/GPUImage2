// TODO: Have this adjust in real time to changing crop sizes
// TODO: Verify at all orientations

public class Crop: BasicOperation {
    public var cropSizeInPixels: Size?
    public var locationOfCropInPixels: Position?
    
    public init() {
        super.init(fragmentShader:PassthroughFragmentShader, numberOfInputs:1)
    }

    override func renderFrame() {
        let inputFramebuffer:Framebuffer = inputFramebuffers[0]!
        let inputSize = inputFramebuffer.sizeForTargetOrientation(.portrait)
        
        let finalCropSize:GLSize
        let normalizedOffsetFromOrigin:Position
        if let cropSize = cropSizeInPixels, let locationOfCrop = locationOfCropInPixels {
            let glCropSize = GLSize(cropSize)
            finalCropSize = GLSize(width:min(inputSize.width, glCropSize.width), height:min(inputSize.height, glCropSize.height))
            normalizedOffsetFromOrigin = Position(locationOfCrop.x / Float(inputSize.width), locationOfCrop.y / Float(inputSize.height))
        } else if let cropSize = cropSizeInPixels {
            let glCropSize = GLSize(cropSize)
            finalCropSize = GLSize(width:min(inputSize.width, glCropSize.width), height:min(inputSize.height, glCropSize.height))
            normalizedOffsetFromOrigin = Position(Float(inputSize.width / 2 - finalCropSize.width / 2) / Float(inputSize.width), Float(inputSize.height / 2 - finalCropSize.height / 2) / Float(inputSize.height))
        } else {
            finalCropSize = inputSize
            normalizedOffsetFromOrigin  = Position.zero
        }
        let normalizedCropSize = Size(width:Float(finalCropSize.width) / Float(inputSize.width), height:Float(finalCropSize.height) / Float(inputSize.height))
        
        renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:finalCropSize, stencil:false)
        
        let textureProperties = InputTextureProperties(textureCoordinates:inputFramebuffer.orientation.rotationNeededForOrientation(.portrait).croppedTextureCoordinates(offsetFromOrigin:normalizedOffsetFromOrigin, cropSize:normalizedCropSize), texture:inputFramebuffer.texture)
        
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:[textureProperties])
        releaseIncomingFramebuffers()
    }
}
