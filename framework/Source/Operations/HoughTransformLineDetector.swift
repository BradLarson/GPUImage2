#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL3
#endif
#endif

//
//  HoughTransformLineDetector.swift
//  GPUImage-Mac
//
//  Created by Max Cantor on 8/6/16.
//  Copyright © 2016 Sunset Lake Software LLC. All rights reserved.
//

import Foundation

public class HoughTransformLineDetector: OperationGroup {

    let thresholdEdgeDetectionFilter = CannyEdgeDetection()
    let nonMaximumSuppression = TextureSamplingOperation(fragmentShader:ThresholdedNonMaximumSuppressionFragmentShader)

    public var linesDetectedCallback:(([Line]) -> ())?
    public var edgeThreshold:Float = 0.9
    public var lineDetectionThreshold:Float = 0.2 { didSet { nonMaximumSuppression.uniformSettings["threshold"] = lineDetectionThreshold } }
    public var cannyBlurRadiusInPixels:Float = 2.0 { didSet { thresholdEdgeDetectionFilter.blurRadiusInPixels = cannyBlurRadiusInPixels } }
    public var cannyUpperThreshold:Float = 0.4 { didSet { thresholdEdgeDetectionFilter.upperThreshold = cannyUpperThreshold } }
    public var cannyLowerThreshold:Float = 0.1 { didSet { thresholdEdgeDetectionFilter.lowerThreshold = cannyLowerThreshold } }

    public override init() {
        super.init()
        let parallelCoordsTransformFilter = ParallelCoordinateLineTransform()
        nonMaximumSuppression.uniformSettings["threshold"] = lineDetectionThreshold

        outputImageRelay.newImageCallback = {[weak self] framebuffer in
            if let linesDetectedCallback = self?.linesDetectedCallback {
                linesDetectedCallback(extractLinesFromImage(framebuffer: framebuffer))
            }
        }

        self.configureGroup {input, output in
            input --> self.thresholdEdgeDetectionFilter --> parallelCoordsTransformFilter --> self.nonMaximumSuppression --> output
        }
    }
}

func extractLinesFromImage(framebuffer: Framebuffer) -> [Line] {
    let frameSize = framebuffer.size
    let pixCount = UInt32(frameSize.width * frameSize.height)
    let chanCount: UInt32 = 4
    let imageByteSize = Int(pixCount * chanCount) // since we're comparing to currentByte, might as well cast here
    let rawImagePixels = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(imageByteSize))
    glReadPixels(0, 0, frameSize.width, frameSize.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), rawImagePixels)
    // since we only set one position with each iteration of the loop, we'll have ot set positions then combine into lines
    //    linesArray = calloc(1024 * 2, sizeof(GLfloat)); - lines is 2048 floats - which is 1024 positions or 528 lines
    var lines = Array<Line>()

    let imageWidthInt = Int(framebuffer.size.width * 4)
//    let startTime = CFAbsoluteTimeGetCurrent()
    var currentByte:Int = 0
//    var cornerStorageIndex: UInt32 = 0
    var lineStrengthCounter: UInt64 = 0
    while (currentByte < imageByteSize) {
        let colorByte = rawImagePixels[currentByte]
        if (colorByte > 0) {
            let xCoordinate = currentByte % imageWidthInt
            let yCoordinate = currentByte / imageWidthInt
            lineStrengthCounter += UInt64(colorByte)
            let normalizedXCoordinate = -1.0 + 2.0 * (Float)(xCoordinate / 4) / Float(frameSize.width)
            let normalizedYCoordinate = -1.0 + 2.0 * (Float)(yCoordinate) / Float(frameSize.height)
//            print("(\(xCoordinate), \(yCoordinate)), [\(rawImagePixels[currentByte]), \(rawImagePixels[currentByte+1]), \(rawImagePixels[currentByte+2]), \(rawImagePixels[currentByte+3]) ] ")
            let nextLine =
                ( normalizedXCoordinate < 0.0
                ? ( normalizedXCoordinate > -0.05
                    // T space
                    // m = -1 - d/u
                    // b = d * v/u
                    ? Line.infinite(slope:100000.0, intercept: normalizedYCoordinate)
                    : Line.infinite(slope: -1.0 - 1.0 / normalizedXCoordinate, intercept: 1.0 * normalizedYCoordinate / normalizedXCoordinate)
                )
                : ( normalizedXCoordinate < 0.05
                    // S space
                    // m = 1 - d/u
                    // b = d * v/u
                    ? Line.infinite(slope: 100000.0, intercept: normalizedYCoordinate)
                    : Line.infinite(slope: 1.0 - 1.0 / normalizedXCoordinate,intercept: 1.0 * normalizedYCoordinate / normalizedXCoordinate)
                    )
                )
            lines.append(nextLine)
        }
        currentByte += 4
    }
    return lines
}
