public class UnsharpMask: OperationGroup {
    public var blurRadiusInPixels: Float { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var intensity: Float = 1.0 { didSet { unsharpMask.uniformSettings["intensity"] = intensity } }
    
    let gaussianBlur = GaussianBlur()
    let unsharpMask = BasicOperation(fragmentShader:UnsharpMaskFragmentShader, numberOfInputs:2)

    public override init() {
        blurRadiusInPixels = 4.0
        super.init()

        ({intensity = 1.0})()

        self.configureGroup{input, output in
            input --> self.unsharpMask
            input --> self.gaussianBlur --> self.unsharpMask --> output
        }
    }
}