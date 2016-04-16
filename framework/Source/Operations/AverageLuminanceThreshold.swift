public class AverageLuminanceThreshold: OperationGroup {
    public var thresholdMultiplier:Float = 1.0
    
    let averageLuminance = AverageLuminanceExtractor()
    let luminanceThreshold = LuminanceThreshold()
    
    public override init() {
        super.init()
        
        averageLuminance.extractedLuminanceCallback = {[weak self] luminance in
            self?.luminanceThreshold.threshold = (self?.thresholdMultiplier ?? 1.0) * luminance
        }
        
        self.configureGroup{input, output in
            input --> self.averageLuminance
            input --> self.luminanceThreshold --> output
        }
    }
}