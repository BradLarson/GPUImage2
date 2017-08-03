//
//  InjectableCamera.swift
//  GPUImage
//
//  Created by Filip Bajanik on 24.7.17.
//  Copyright © 2017 Sunset Lake Software LLC. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ImageIO


/// Errors describing InjectableCamera
enum InjectableCameraError: Error, LocalizedError {
    case hasNoVideoOutput
    
    var errorDescription: String? {
        switch self {
        case .hasNoVideoOutput:
            return "Camera has no video output initialized"
        }
    }
}


/// ImageSource taking frames from AVCaptureSession calling
/// the original AVCaptureVideoDataOutputSampleBufferDelegate.
public class InjectableCamera: NSObject, ImageSource {
    
    // MARK: - Properties
    
    public let targets = TargetContainer()
    public var runBenchmark: Bool = false
    public var logFPS: Bool = false
    public var onExifCaptured: ((_ exifData: CFTypeRef) -> ())?
    
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var location: PhysicalCameraLocation
    
    fileprivate var originalCaptureVideoDataOutputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    fileprivate let frameRenderingSemaphore = DispatchSemaphore(value:1)
    
    // Logging properties
    fileprivate var numberOfFramesCaptured = 0
    fileprivate var totalFrameTimeDuringCapture:Double = 0.0
    fileprivate var framesSinceLastCheck = 0
    fileprivate var lastCheckTime = CFAbsoluteTimeGetCurrent()
    
    // YUV
    fileprivate var supportsFullYUVRange: Bool! = false
    fileprivate var captureAsYUV: Bool
    fileprivate var yuvConversionShader: ShaderProgram?
    
    // MARK: - Initialization
    
    public init(withSession session: AVCaptureSession,
                location: PhysicalCameraLocation = .frontFacing,
                captureAsYUV: Bool = true) throws {
        
        self.location = location
        self.captureAsYUV = captureAsYUV
        super.init()
        
        var hasOriginalVideoOutput = false
        
        for output in session.outputs {
            if let videoOutput = output as? AVCaptureVideoDataOutput {
                self.videoOutput = videoOutput
                
                initializeYUVSupport(fromVideoOutput: videoOutput)
                
                // Store the original video output delegate for further usage
                self.originalCaptureVideoDataOutputDelegate = videoOutput.sampleBufferDelegate;
                
                // Assign our own delegate
                videoOutput.setSampleBufferDelegate(self, queue: .main)
                
                hasOriginalVideoOutput = true
                continue
            }
        }
        
        if !hasOriginalVideoOutput {
            throw InjectableCameraError.hasNoVideoOutput
        }
    }
    
    deinit {
        sharedImageProcessingContext.runOperationSynchronously {
            self.videoOutput?.setSampleBufferDelegate(
                originalCaptureVideoDataOutputDelegate, queue: .main)
        }
    }
    
    // MARK: - ImageSource
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt) {
        // Implementation is not needed for camera input
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension InjectableCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Notifies the delegate that a sample buffer was written and then notify the original delegate
    public func captureOutput(_ captureOutput: AVCaptureOutput!,
                              didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                              from connection: AVCaptureConnection!) {
        
        // Capture and handle image
        let isVideo = captureOutput is AVCaptureVideoDataOutput
        if isVideo {
            handleExifData(sampleBuffer)
            handleSampleBuffer(sampleBuffer)
        }
        
        // Send sampleBuffer to the original delegate
        self.originalCaptureVideoDataOutputDelegate?.captureOutput!(
            captureOutput, didOutputSampleBuffer: sampleBuffer, from: connection)
    }
}

// MARK: - Frame handling methods
fileprivate extension InjectableCamera {
    
    func handleExifData(_ sampleBuffer: CMSampleBuffer) {
        guard let onExifCaptured = onExifCaptured else { return }
        
        if let exif = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary as NSString, nil) {
            onExifCaptured(exif)
        }
    }
    
    func initializeYUVSupport(fromVideoOutput videoOutput: AVCaptureVideoDataOutput) {
        let pixelFormatType: NSNumber
        
        if captureAsYUV {
            supportsFullYUVRange = false
            let supportedPixelFormats = videoOutput.availableVideoCVPixelFormatTypes
            for currentPixelFormat in supportedPixelFormats! {
                let currentPixelFormatValue = (currentPixelFormat as! NSNumber).int32Value
                let yuvPixelFormatValue = Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                
                supportsFullYUVRange = currentPixelFormatValue == yuvPixelFormatValue
            }
            
            let fragmentShader: String
            if (supportsFullYUVRange) {
                fragmentShader = YUVConversionFullRangeFragmentShader
                pixelFormatType = NSNumber(value: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))
            } else {
                fragmentShader = YUVConversionVideoRangeFragmentShader
                pixelFormatType = NSNumber(value: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange))
            }
            
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: pixelFormatType]
            yuvConversionShader = crashOnShaderCompileFailure("Camera") {
                try sharedImageProcessingContext.programForVertexShader(
                    defaultVertexShaderForInputs(2),
                    fragmentShader: fragmentShader)
            }
        } else {
            yuvConversionShader = nil
            pixelFormatType = NSNumber(value: Int32(kCVPixelFormatType_32BGRA))
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: pixelFormatType]
        }
    }
    
    /// Handle sample buffer and notify InputSource with new Framebuffer
    ///  - this method is transforming CMSampleBuffer into Framebuffer for OpenGL
    ///
    /// - Parameter sampleBuffer: sample buffer from the AVCaptureVideoDataOutput
    func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        // Acquire semaphore for analyzing the buffer
        guard frameRenderingSemaphore.wait(timeout: DispatchTime.now()) == DispatchTimeoutResult.success else { return }
        
        // For logging purposes
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Creating frame from the buffer and it's properties
        let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Lock access to the frame buffer and analyze the input
        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        sharedImageProcessingContext.runOperationAsynchronously {
            let cameraFramebuffer: Framebuffer
            
            let frameBufferCache = sharedImageProcessingContext.framebufferCache
            
            if (self.captureAsYUV) {
                let luminanceFramebuffer = self.getLuminanceFramebuffer(
                    cameraFrame: cameraFrame, width: bufferWidth, height: bufferHeight)
                
                let chrominanceFramebuffer = self.getChrominanceFramebuffer(
                    cameraFrame: cameraFrame, width: bufferWidth, height: bufferHeight)
                
                let conversionMatrix: Matrix3x3
                if self.supportsFullYUVRange {
                    conversionMatrix = colorConversionMatrix601FullRangeDefault
                } else {
                    conversionMatrix = colorConversionMatrix601Default
                }
                
                let framebufferSize = luminanceFramebuffer.sizeForTargetOrientation(.portrait)
                cameraFramebuffer = frameBufferCache.requestFramebufferWithProperties(
                    orientation: .portrait, size: framebufferSize, textureOnly: false)
                
                convertYUVToRGB(
                    shader: self.yuvConversionShader!,
                    luminanceFramebuffer: luminanceFramebuffer,
                    chrominanceFramebuffer: chrominanceFramebuffer,
                    resultFramebuffer: cameraFramebuffer,
                    colorConversionMatrix: conversionMatrix)
            } else {
                let framebufferSize = GLSize(width: GLint(bufferWidth), height: GLint(bufferHeight))
                cameraFramebuffer = frameBufferCache.requestFramebufferWithProperties(
                    orientation: self.location.imageOrientation(),
                    size: framebufferSize, textureOnly: true)
                
                glBindTexture(GLenum(GL_TEXTURE_2D), cameraFramebuffer.texture)
                glTexImage2D(
                    GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(bufferWidth),
                    GLsizei(bufferHeight), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE),
                    CVPixelBufferGetBaseAddress(cameraFrame))
            }
            
            // Unlock access to the frame buffer
            CVPixelBufferUnlockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            cameraFramebuffer.timingStyle = .videoFrame(timestamp: Timestamp(currentTime))
            self.updateTargetsWithFramebuffer(cameraFramebuffer)
            
            self.doLog()
            self.doBenchmark(startedFromTime: startTime)
            
            // Release semaphore
            self.frameRenderingSemaphore.signal()
        }
    }
}

// MARK: - Framebuffer conversions
fileprivate extension InjectableCamera {
    
    func getLuminanceFramebuffer(cameraFrame: CVImageBuffer, width: Int, height: Int) -> Framebuffer {
        
        let luminanceFramebuffer: Framebuffer
        let videoTextureCache = sharedImageProcessingContext.coreVideoTextureCache
        let frameBufferCache = sharedImageProcessingContext.framebufferCache
        
        if sharedImageProcessingContext.supportsTextureCaches() {
            var luminanceTextureRef:CVOpenGLESTexture? = nil
            
            CVOpenGLESTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault, videoTextureCache, cameraFrame,
                nil, GLenum(GL_TEXTURE_2D), GL_LUMINANCE, GLsizei(width),
                GLsizei(height), GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE),
                0, &luminanceTextureRef)
            
            let luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef!)
            glActiveTexture(GLenum(GL_TEXTURE4))
            glBindTexture(GLenum(GL_TEXTURE_2D), luminanceTexture)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
            
            luminanceFramebuffer = try! Framebuffer(
                context: sharedImageProcessingContext,
                orientation: location.imageOrientation(),
                size: GLSize(width: GLint(width), height: GLint(height)),
                textureOnly: true,
                overriddenTexture: luminanceTexture)
        } else {
            glActiveTexture(GLenum(GL_TEXTURE4))
            luminanceFramebuffer = frameBufferCache.requestFramebufferWithProperties(
                orientation: location.imageOrientation(),
                size: GLSize(width:GLint(width), height: GLint(height)),
                textureOnly: true)
            
            luminanceFramebuffer.lock()
            
            glBindTexture(GLenum(GL_TEXTURE_2D), luminanceFramebuffer.texture)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(width),
                         GLsizei(height), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE),
                         CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0))
        }
        
        return luminanceFramebuffer
    }
    
    func getChrominanceFramebuffer(cameraFrame: CVImageBuffer, width: Int, height: Int) -> Framebuffer {
        
        let chrominanceFramebuffer:Framebuffer
        let videoTextureCache = sharedImageProcessingContext.coreVideoTextureCache
        let frameBufferCache = sharedImageProcessingContext.framebufferCache
        
        if sharedImageProcessingContext.supportsTextureCaches() {
            var chrominanceTextureRef: CVOpenGLESTexture? = nil
            
            CVOpenGLESTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault, videoTextureCache, cameraFrame,
                nil, GLenum(GL_TEXTURE_2D), GL_LUMINANCE_ALPHA,
                GLsizei(width / 2), GLsizei(height / 2), GLenum(GL_LUMINANCE_ALPHA),
                GLenum(GL_UNSIGNED_BYTE), 1, &chrominanceTextureRef)
            
            let chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef!)
            glActiveTexture(GLenum(GL_TEXTURE5))
            glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceTexture)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
            
            chrominanceFramebuffer = try! Framebuffer(
                context: sharedImageProcessingContext,
                orientation: location.imageOrientation(),
                size: GLSize(width: GLint(width / 2), height: GLint(height / 2)),
                textureOnly: true,
                overriddenTexture: chrominanceTexture)
        } else {
            glActiveTexture(GLenum(GL_TEXTURE5))
            chrominanceFramebuffer = frameBufferCache.requestFramebufferWithProperties(
                orientation: location.imageOrientation(),
                size: GLSize(width: GLint(width / 2), height: GLint(height / 2)),
                textureOnly: true)
            
            chrominanceFramebuffer.lock()
            
            glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceFramebuffer.texture)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE_ALPHA,
                         GLsizei(width / 2), GLsizei(height / 2), 0, GLenum(GL_LUMINANCE_ALPHA),
                         GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1))
        }
        
        return chrominanceFramebuffer
    }
}

// MARK: - Logging and benchmarking
fileprivate extension InjectableCamera {
    
    func doLog() {
        if !logFPS { return }
        
        if (CFAbsoluteTimeGetCurrent() - lastCheckTime) > 1.0 {
            lastCheckTime = CFAbsoluteTimeGetCurrent()
            print("FPS: \(framesSinceLastCheck)")
            framesSinceLastCheck = 0
        }
        
        framesSinceLastCheck += 1
    }
    
    func doBenchmark(startedFromTime startTime: CFAbsoluteTime) {
        if !runBenchmark { return }
        
        numberOfFramesCaptured += 1
        if numberOfFramesCaptured > initialBenchmarkFramesToIgnore {
            let currentFrameTime = CFAbsoluteTimeGetCurrent() - startTime
            totalFrameTimeDuringCapture += currentFrameTime
            
            let averageFrameTime = 1000.0 * totalFrameTimeDuringCapture /
                Double(numberOfFramesCaptured - initialBenchmarkFramesToIgnore)
            
            print("Average frame time : \(averageFrameTime) ms")
            print("Current frame time : \(1000.0 * currentFrameTime) ms")
        }
    }
}
