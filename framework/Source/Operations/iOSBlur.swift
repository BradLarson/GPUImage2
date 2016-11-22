open class iOSBlur: OperationGroup {
    open var blurRadiusInPixels:Float = 48.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    open var saturation:Float = 0.8 { didSet { saturationFilter.saturation = saturation } }
    open var rangeReductionFactor:Float = 0.6 { didSet { luminanceRange.rangeReductionFactor = rangeReductionFactor } }
    
    let saturationFilter = SaturationAdjustment()
    let gaussianBlur = GaussianBlur()
    let luminanceRange = LuminanceRangeReduction()
    
    public override init() {
        super.init()
        
        ({blurRadiusInPixels = 48.0})()
        ({saturation = 0.8})()
        ({rangeReductionFactor = 0.6})()
        
        self.configureGroup{input, output in
            input --> self.saturationFilter --> self.gaussianBlur --> self.luminanceRange --> output
        }
    }
}
