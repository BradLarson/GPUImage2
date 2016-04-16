public class AdaptiveThreshold: OperationGroup {
    public var blurRadiusInPixels: Float { didSet { boxBlur.blurRadiusInPixels = blurRadiusInPixels } }
    
    let luminance = Luminance()
    let boxBlur = BoxBlur()
    let adaptiveThreshold = BasicOperation(fragmentShader:AdaptiveThresholdFragmentShader, numberOfInputs:2)
    
    public override init() {
        blurRadiusInPixels = 4.0
        super.init()
        
        self.configureGroup{input, output in
            input --> self.luminance --> self.boxBlur --> self.adaptiveThreshold --> output
                      self.luminance --> self.adaptiveThreshold
        }
    }
}