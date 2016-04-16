public class LowPassFilter: OperationGroup {
    public var strength: Float = 0.5 { didSet { dissolveBlend.mix = strength } }
    
    let dissolveBlend = DissolveBlend()
    let buffer = ImageBuffer()
    
    public override init() {
        super.init()
        
        buffer.bufferSize = 1
        ({strength = 0.5})()
        
        self.configureGroup{input, output in
            // This is needed to break the cycle on the very first pass through the blend loop
            self.dissolveBlend.activatePassthroughOnNextFrame = true
            // TODO: this may be a retain cycle
            input --> self.dissolveBlend --> self.buffer --> self.dissolveBlend --> output
        }
    }
}