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

public class InjectableCamera: NSObject {

    // MARK: - Properties
    
    public let targets = TargetContainer()
    fileprivate var originalCaptureVideoDataOutputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?

    // MARK: - Initialization
    
    public init(withSession session: AVCaptureSession) throws {
        super.init()
        var hasOriginalVideoOutput = false
        
        for output in session.outputs {
            if let videoOutput = output as? AVCaptureVideoDataOutput {
                
                // Store the original video output delegate for further usage
                self.originalCaptureVideoDataOutputDelegate = videoOutput.sampleBufferDelegate;
                
                // Assign our own delegate
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                
                hasOriginalVideoOutput = true
                continue
            }
        }
        
        if !hasOriginalVideoOutput {
            throw InjectableCameraError.hasNoVideoOutput
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension InjectableCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Notifies the delegate that a sample buffer was written and then notify the original RTC delegate
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // Capture image
        let isVideo = captureOutput is AVCaptureVideoDataOutput
        if isVideo, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            //let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            
            // Get UIImage
            // let _ = UIImage.convert(from: ciimage)
        }
        
        // Send sampleBuffer to the original delegate
        self.originalCaptureVideoDataOutputDelegate?.captureOutput!(
            captureOutput, didOutputSampleBuffer: sampleBuffer, from: connection)
    }
}

// MARK: - ImageSource
extension InjectableCamera: ImageSource {
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt) {
        // Implementation is not needed for camera input
    }
}
