open class ZoomBlur: BasicOperation {
    open var blurSize:Float = 1.0 { didSet { uniformSettings["blurSize"] = blurSize } }
    open var blurCenter:Position = Position.center { didSet { uniformSettings["blurCenter"] = blurCenter } }
    
    public init() {
        super.init(fragmentShader:ZoomBlurFragmentShader, numberOfInputs:1)
        
        ({blurSize = 1.0})()
        ({blurCenter = Position.center})()
    }
}
