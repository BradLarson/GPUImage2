public class TiltShift: OperationGroup {
    public var blurRadiusInPixels:Float = 7.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var topFocusLevel:Float = 0.4 { didSet { tiltShift.uniformSettings["topFocusLevel"] = topFocusLevel } }
    public var bottomFocusLevel:Float = 0.6 { didSet { tiltShift.uniformSettings["bottomFocusLevel"] = bottomFocusLevel } }
    public var focusFallOffRate:Float = 0.2 { didSet { tiltShift.uniformSettings["focusFallOffRate"] = focusFallOffRate } }

    let gaussianBlur = GaussianBlur()
    let tiltShift = BasicOperation(fragmentShader:TiltShiftFragmentShader, numberOfInputs:2)
    
    public override init() {
        super.init()

        ({blurRadiusInPixels = 7.0})()
        ({topFocusLevel = 0.4})()
        ({bottomFocusLevel = 0.6})()
        ({focusFallOffRate = 0.2})()

        self.configureGroup{input, output in
            input --> self.tiltShift --> output
            input --> self.gaussianBlur --> self.tiltShift
        }
    }
}