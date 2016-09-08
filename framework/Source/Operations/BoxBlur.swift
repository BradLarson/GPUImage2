#if os(Linux)
import Glibc
#endif

import Foundation

public class BoxBlur: TwoStageOperation {
    public var blurRadiusInPixels:Float {
        didSet {
            let (sigma, downsamplingFactor) = sigmaAndDownsamplingForBlurRadius(blurRadiusInPixels, limit:8.0, override:overrideDownsamplingOptimization)
            sharedImageProcessingContext.runOperationAsynchronously {
                self.downsamplingFactor = downsamplingFactor
                let pixelRadius = pixelRadiusForBlurSigma(Double(sigma))
                self.shader = crashOnShaderCompileFailure("BoxBlur"){try sharedImageProcessingContext.programForVertexShader(vertexShaderForOptimizedBoxBlurOfRadius(pixelRadius), fragmentShader:fragmentShaderForOptimizedBoxBlurOfRadius(pixelRadius))}
            }
        }
    }
    
    public init() {
        blurRadiusInPixels = 2.0
        let pixelRadius = UInt(round(round(Double(blurRadiusInPixels) / 2.0) * 2.0))
        let initialShader = crashOnShaderCompileFailure("BoxBlur"){try sharedImageProcessingContext.programForVertexShader(vertexShaderForOptimizedBoxBlurOfRadius(pixelRadius), fragmentShader:fragmentShaderForOptimizedBoxBlurOfRadius(pixelRadius))}
        super.init(shader:initialShader, numberOfInputs:1)
    }
}

func vertexShaderForOptimizedBoxBlurOfRadius(_ radius:UInt) -> String {
    guard (radius > 0) else { return OneInputVertexShader }

    let numberOfOptimizedOffsets = min(radius / 2 + (radius % 2), 7)
    var shaderString = "attribute vec4 position;\n attribute vec4 inputTextureCoordinate;\n \n uniform float texelWidth;\n uniform float texelHeight;\n \n varying vec2 blurCoordinates[\(1 + (numberOfOptimizedOffsets * 2))];\n \n void main()\n {\n gl_Position = position;\n \n vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
    shaderString += "blurCoordinates[0] = inputTextureCoordinate.xy;\n"
    for currentOptimizedOffset in 0..<numberOfOptimizedOffsets {
        let optimizedOffset = Float(currentOptimizedOffset * 2) + 1.5
        shaderString += "blurCoordinates[\((currentOptimizedOffset * 2) + 1)] = inputTextureCoordinate.xy + singleStepOffset * \(optimizedOffset);\n"
        shaderString += "blurCoordinates[\((currentOptimizedOffset * 2) + 2)] = inputTextureCoordinate.xy + singleStepOffset * \(optimizedOffset);\n"
    }
    
    shaderString += "}\n"
    return shaderString
}

func fragmentShaderForOptimizedBoxBlurOfRadius(_ radius:UInt) -> String {
    guard (radius > 0) else { return PassthroughFragmentShader }
    
    let numberOfOptimizedOffsets = min(radius / 2 + (radius % 2), 7)
    let trueNumberOfOptimizedOffsets = radius / 2 + (radius % 2)

    // Header
#if GLES
    var shaderString = "uniform sampler2D inputImageTexture;\n uniform highp float texelWidth;\n uniform highp float texelHeight;\n \n varying highp vec2 blurCoordinates[\(1 + (numberOfOptimizedOffsets * 2))];\n \n void main()\n {\n lowp vec4 sum = vec4(0.0);\n"
#else
    var shaderString = "uniform sampler2D inputImageTexture;\n uniform float texelWidth;\n uniform float texelHeight;\n \n varying vec2 blurCoordinates[\((1 + (numberOfOptimizedOffsets * 2)))];\n \n void main()\n {\n vec4 sum = vec4(0.0);\n"
#endif

    // Inner texture loop
    let boxWeight = 1.0 / Float((radius * 2) + 1)
    shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0]) * \(boxWeight);\n"
    for currentBlurCoordinateIndex in 0..<numberOfOptimizedOffsets {
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\(((currentBlurCoordinateIndex * 2) + 1))]) * \(boxWeight * 2.0);\n"
        shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[\(((currentBlurCoordinateIndex * 2) + 2))]) * \(boxWeight * 2.0);\n"
    }
    
    // If the number of required samples exceeds the amount we can pass in via varyings, we have to do dependent texture reads in the fragment shader
    if (trueNumberOfOptimizedOffsets > numberOfOptimizedOffsets) {
#if GLES
        shaderString += "highp vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
#else
        shaderString += "vec2 singleStepOffset = vec2(texelWidth, texelHeight);\n"
#endif
        for currentOverlowTextureRead in numberOfOptimizedOffsets..<trueNumberOfOptimizedOffsets {
            let optimizedOffset = Float(currentOverlowTextureRead * 2) + 1.5

            shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset * \(optimizedOffset)) * \(boxWeight * 2.0);\n"
            shaderString += "sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * \(optimizedOffset)) * \(boxWeight * 2.0);\n"
        }
    }
    
    // Footer
    shaderString += "gl_FragColor = sum;\n }\n"
    return shaderString
}
