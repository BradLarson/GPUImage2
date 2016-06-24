public class SingleComponentGaussianBlur: TwoStageOperation {
    public var blurRadiusInPixels:Float {
        didSet {
            let (sigma, downsamplingFactor) = sigmaAndDownsamplingForBlurRadius(blurRadiusInPixels, limit:8.0, override:overrideDownsamplingOptimization)
            sharedImageProcessingContext.runOperationAsynchronously {
                self.downsamplingFactor = downsamplingFactor
                let pixelRadius = pixelRadiusForBlurSigma(Double(sigma))
                self.shader = crashOnShaderCompileFailure("GaussianBlur"){try sharedImageProcessingContext.programForVertexShader(vertexShaderForOptimizedGaussianBlurOfRadius(pixelRadius, sigma:Double(sigma)), fragmentShader:fragmentShaderForOptimizedSingleComponentGaussianBlurOfRadius(pixelRadius, sigma:Double(sigma)))}
            }
        }
    }
    
    public init() {
        blurRadiusInPixels = 2.0
        let pixelRadius = pixelRadiusForBlurSigma(Double(blurRadiusInPixels))
        let initialShader = crashOnShaderCompileFailure("GaussianBlur"){try sharedImageProcessingContext.programForVertexShader(vertexShaderForOptimizedGaussianBlurOfRadius(pixelRadius, sigma:2.0), fragmentShader:fragmentShaderForOptimizedSingleComponentGaussianBlurOfRadius(pixelRadius, sigma:2.0))}
        super.init(shader:initialShader, numberOfInputs:1)
    }
    
}

func fragmentShaderForOptimizedSingleComponentGaussianBlurOfRadius(_ radius:UInt, sigma:Double) -> String {
    guard (radius > 0) else { return PassthroughFragmentShader }
    
    let standardWeights = standardGaussianWeightsForRadius(radius, sigma:sigma)
    let numberOfOptimizedOffsets = min(radius / 2 + (radius % 2), 7)
    let trueNumberOfOptimizedOffsets = radius / 2 + (radius % 2)
    
    #if GLES
        var shaderString = "uniform sampler2D inputImageTexture;\n uniform highp float texelWidth;\n uniform highp float texelHeight;\n \n varying highp vec2 blurCoordinates[\(1 + (numberOfOptimizedOffsets * 2))];\n \n void main()\n {\n lowp float sum = 0.0;\n"
    #else
        var shaderString = "uniform sampler2D inputImageTexture;\n uniform float texelWidth;\n uniform float texelHeight;\n \n varying vec2 blurCoordinates[\(1 + (numberOfOptimizedOffsets * 2))];\n \n void main()\n {\n float sum = 0.0;\n"
    #endif
    
    // Inner texture loop
    shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0]).r * \(standardWeights[0]);\n"
    
    for currentBlurCoordinateIndex in 0..<numberOfOptimizedOffsets {
        let firstWeight = standardWeights[Int(currentBlurCoordinateIndex * 2 + 1)]
        let secondWeight = standardWeights[Int(currentBlurCoordinateIndex * 2 + 2)]
        let optimizedWeight = firstWeight + secondWeight
        
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\((currentBlurCoordinateIndex * 2) + 1)]).r * \(optimizedWeight);\n"
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\((currentBlurCoordinateIndex * 2) + 2)]).r * \(optimizedWeight);\n"
    }
    
    // If the number of required samples exceeds the amount we can pass in via varyings, we have to do dependent texture reads in the fragment shader
    if (trueNumberOfOptimizedOffsets > numberOfOptimizedOffsets) {
        #if GLES
            shaderString += "highp vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
        #else
            shaderString += "vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
        #endif
    }
    
    for currentOverlowTextureRead in numberOfOptimizedOffsets..<trueNumberOfOptimizedOffsets {
        let firstWeight = standardWeights[Int(currentOverlowTextureRead * 2 + 1)];
        let secondWeight = standardWeights[Int(currentOverlowTextureRead * 2 + 2)];
        
        let optimizedWeight = firstWeight + secondWeight
        let optimizedOffset = (firstWeight * (Double(currentOverlowTextureRead) * 2.0 + 1.0) + secondWeight * (Double(currentOverlowTextureRead) * 2.0 + 2.0)) / optimizedWeight
        
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset * \(optimizedOffset)).r * \(optimizedWeight);\n"
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * \(optimizedOffset)).r * \(optimizedWeight);\n"
    }
    
    shaderString += "gl_FragColor = vec4(sum, sum, sum, 1.0);\n }\n"
    
    return shaderString
}
