#if os(Linux)
import Glibc
let M_PI = 3.14159265359 // TODO: remove this once Foundation pulls this in on Linux
#endif

import Foundation

public class GaussianBlur: TwoStageOperation {
    public var blurRadiusInPixels:Float {
        didSet {
            let (sigma, downsamplingFactor) = sigmaAndDownsamplingForBlurRadius(blurRadiusInPixels, limit:8.0, override:overrideDownsamplingOptimization)
            sharedImageProcessingContext.runOperationAsynchronously {
                self.downsamplingFactor = downsamplingFactor
                let pixelRadius = pixelRadiusForBlurSigma(Double(sigma))
                self.shader = crashOnShaderCompileFailure("GaussianBlur"){try sharedImageProcessingContext.programForVertexShader(vertexShaderForOptimizedGaussianBlurOfRadius(pixelRadius, sigma:Double(sigma)), fragmentShader:fragmentShaderForOptimizedGaussianBlurOfRadius(pixelRadius, sigma:Double(sigma)))}
            }
        }
    }
    
    public init() {
        blurRadiusInPixels = 2.0
        let pixelRadius = pixelRadiusForBlurSigma(round(Double(blurRadiusInPixels)))
        let initialShader = crashOnShaderCompileFailure("GaussianBlur"){try sharedImageProcessingContext.programForVertexShader(vertexShaderForOptimizedGaussianBlurOfRadius(pixelRadius, sigma:2.0), fragmentShader:fragmentShaderForOptimizedGaussianBlurOfRadius(pixelRadius, sigma:2.0))}
        super.init(shader:initialShader, numberOfInputs:1)
    }
    
}

// MARK: -
// MARK: Blur sizing calculations

func sigmaAndDownsamplingForBlurRadius(_ radius:Float, limit:Float, override:Bool = false) -> (sigma:Float, downsamplingFactor:Float?) {
    // For now, only do integral sigmas
    let startingRadius = Float(round(Double(radius)))
    guard ((startingRadius > limit) && (!override)) else { return (sigma:startingRadius, downsamplingFactor:nil) }
    
    return (sigma:limit, downsamplingFactor:startingRadius / limit)
}


// inputRadius for Core Image's CIGaussianBlur is really sigma in the Gaussian equation, so I'm using that for my blur radius, to be consistent
func pixelRadiusForBlurSigma(_ sigma:Double) -> UInt {
    // 7.0 is the limit for blur size for hardcoded varying offsets
    let minimumWeightToFindEdgeOfSamplingArea = 1.0 / 256.0
    
    var calculatedSampleRadius:UInt = 0
    if (sigma >= 1.0) { // Avoid a divide-by-zero error here
        // Calculate the number of pixels to sample from by setting a bottom limit for the contribution of the outermost pixel
        calculatedSampleRadius = UInt(floor(sqrt(-2.0 * pow(sigma, 2.0) * log(minimumWeightToFindEdgeOfSamplingArea * sqrt(2.0 * .pi * pow(sigma, 2.0))) )))
        calculatedSampleRadius += calculatedSampleRadius % 2 // There's nothing to gain from handling odd radius sizes, due to the optimizations I use
    }
    
    return calculatedSampleRadius
}

// MARK: -
// MARK: Standard Gaussian blur shaders

func standardGaussianWeightsForRadius(_ blurRadius:UInt, sigma:Double) -> [Double] {
    var gaussianWeights = [Double]()
    var sumOfWeights = 0.0
    for gaussianWeightIndex in 0...blurRadius {
        let weight = (1.0 / sqrt(2.0 * .pi * pow(sigma, 2.0))) * exp(-pow(Double(gaussianWeightIndex), 2.0) / (2.0 * pow(sigma, 2.0)))
        gaussianWeights.append(weight)
        if (gaussianWeightIndex == 0) {
            sumOfWeights += weight
        } else {
            sumOfWeights += (weight * 2.0)
        }
    }
    
    return gaussianWeights.map{$0 / sumOfWeights}
}

func vertexShaderForStandardGaussianBlurOfRadius(_ radius:UInt, sigma:Double) -> String {
    guard (radius > 0) else { return OneInputVertexShader }
    
    let numberOfBlurCoordinates = radius * 2 + 1
    var shaderString = "attribute vec4 position;\n attribute vec4 inputTextureCoordinate;\n \n uniform float texelWidth;\n uniform float texelHeight;\n \n varying vec2 blurCoordinates[\(numberOfBlurCoordinates)];\n \n void main()\n {\n gl_Position = position;\n \n vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
    for currentBlurCoordinateIndex in 0..<numberOfBlurCoordinates {
        let offsetFromCenter = Int(currentBlurCoordinateIndex) - Int(radius)
        if (offsetFromCenter < 0) {
            shaderString += "blurCoordinates[\(currentBlurCoordinateIndex)] = inputTextureCoordinate.xy - singleStepOffset * \(Float(-offsetFromCenter));\n"
        } else if (offsetFromCenter > 0) {
            shaderString += "blurCoordinates[\(currentBlurCoordinateIndex)] = inputTextureCoordinate.xy + singleStepOffset * \(Float(offsetFromCenter));\n"
        } else {
            shaderString += "blurCoordinates[\(currentBlurCoordinateIndex)] = inputTextureCoordinate.xy;\n"
        }
    }
    
    shaderString += "}\n"
    return shaderString
}

func fragmentShaderForStandardGaussianBlurOfRadius(_ radius:UInt, sigma:Double) -> String {
    guard (radius > 0) else { return PassthroughFragmentShader }

    let gaussianWeights = standardGaussianWeightsForRadius(radius, sigma:sigma)
    
    let numberOfBlurCoordinates = radius * 2 + 1
#if GLES
    var shaderString = "uniform sampler2D inputImageTexture;\n \n varying highp vec2 blurCoordinates[\(numberOfBlurCoordinates)];\n \n void main()\n {\n lowp vec4 sum = vec4(0.0);\n"
#else
    var shaderString = "uniform sampler2D inputImageTexture;\n \n varying vec2 blurCoordinates[\(numberOfBlurCoordinates)];\n \n void main()\n {\n vec4 sum = vec4(0.0);\n"
#endif

    for currentBlurCoordinateIndex in 0..<numberOfBlurCoordinates {
        let offsetFromCenter = Int(currentBlurCoordinateIndex) - Int(radius)
        if (offsetFromCenter < 0) {
            shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\(currentBlurCoordinateIndex)]) * \(gaussianWeights[-offsetFromCenter]);\n"
        } else {
            shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\(currentBlurCoordinateIndex)]) * \(gaussianWeights[offsetFromCenter]);\n"
        }
    }
    shaderString += "gl_FragColor = sum;\n }\n"
    return shaderString
}

// MARK: -
// MARK: Optimized Gaussian blur shaders

func optimizedGaussianOffsetsForRadius(_ blurRadius:UInt, sigma:Double) -> [Double] {
    let standardWeights = standardGaussianWeightsForRadius(blurRadius, sigma:sigma)
    let numberOfOptimizedOffsets = min(blurRadius / 2 + (blurRadius % 2), 7)
    
    var optimizedOffsets = [Double]()
    for currentOptimizedOffset in 0..<numberOfOptimizedOffsets {
        let firstWeight = Double(standardWeights[Int(currentOptimizedOffset * 2 + 1)])
        let secondWeight = Double(standardWeights[Int(currentOptimizedOffset * 2 + 2)])
        let optimizedWeight = firstWeight + secondWeight

        optimizedOffsets.append((firstWeight * (Double(currentOptimizedOffset) * 2.0 + 1.0) + secondWeight * (Double(currentOptimizedOffset) * 2.0 + 2.0)) / optimizedWeight)
    }
    
    return optimizedOffsets
}

func vertexShaderForOptimizedGaussianBlurOfRadius(_ radius:UInt, sigma:Double) -> String {
    guard (radius > 0) else { return OneInputVertexShader }

    let optimizedOffsets = optimizedGaussianOffsetsForRadius(radius, sigma:sigma)
    let numberOfOptimizedOffsets = optimizedOffsets.count
    
    // Header
    var shaderString = "attribute vec4 position;\n attribute vec4 inputTextureCoordinate;\n \n uniform float texelWidth;\n uniform float texelHeight;\n \n varying vec2 blurCoordinates[\((1 + (numberOfOptimizedOffsets * 2)))];\n \n void main()\n {\n gl_Position = position;\n \n vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
    shaderString += "blurCoordinates[0] = inputTextureCoordinate.xy;\n"
    for currentOptimizedOffset in 0..<numberOfOptimizedOffsets {
        shaderString += "blurCoordinates[\(((currentOptimizedOffset * 2) + 1))] = inputTextureCoordinate.xy + singleStepOffset * \(optimizedOffsets[currentOptimizedOffset]);\n"
        shaderString += "blurCoordinates[\(((currentOptimizedOffset * 2) + 2))] = inputTextureCoordinate.xy - singleStepOffset * \(optimizedOffsets[currentOptimizedOffset]);\n"
    }
    
    shaderString += "}\n"
    return shaderString
}

func fragmentShaderForOptimizedGaussianBlurOfRadius(_ radius:UInt, sigma:Double) -> String {
    guard (radius > 0) else { return PassthroughFragmentShader }
    
    let standardWeights = standardGaussianWeightsForRadius(radius, sigma:sigma)
    let numberOfOptimizedOffsets = min(radius / 2 + (radius % 2), 7)
    let trueNumberOfOptimizedOffsets = radius / 2 + (radius % 2)

#if GLES
        var shaderString = "uniform sampler2D inputImageTexture;\n uniform highp float texelWidth;\n uniform highp float texelHeight;\n \n varying highp vec2 blurCoordinates[\(1 + (numberOfOptimizedOffsets * 2))];\n \n void main()\n {\n lowp vec4 sum = vec4(0.0);\n"
#else
        var shaderString = "uniform sampler2D inputImageTexture;\n uniform float texelWidth;\n uniform float texelHeight;\n \n varying vec2 blurCoordinates[\(1 + (numberOfOptimizedOffsets * 2))];\n \n void main()\n {\n vec4 sum = vec4(0.0);\n"
#endif

    // Inner texture loop
    shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0]) * \(standardWeights[0]);\n"
    
    for currentBlurCoordinateIndex in 0..<numberOfOptimizedOffsets {
        let firstWeight = standardWeights[Int(currentBlurCoordinateIndex * 2 + 1)]
        let secondWeight = standardWeights[Int(currentBlurCoordinateIndex * 2 + 2)]
        let optimizedWeight = firstWeight + secondWeight
        
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\((currentBlurCoordinateIndex * 2) + 1)]) * \(optimizedWeight);\n"
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\((currentBlurCoordinateIndex * 2) + 2)]) * \(optimizedWeight);\n"
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
        
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset * \(optimizedOffset)) * \(optimizedWeight);\n"
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * \(optimizedOffset)) * \(optimizedWeight);\n"
    }
    
    shaderString += "gl_FragColor = sum;\n }\n"
    
    return shaderString
}
