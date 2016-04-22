import Foundation
import AVFoundation

public class Camera: NSObject, ImageSource, AVCaptureVideoDataOutputSampleBufferDelegate {
    public let targets = TargetContainer()
    public var orientation:ImageOrientation
    
    let captureSession:AVCaptureSession
    let inputCamera:AVCaptureDevice
    let videoInput:AVCaptureDeviceInput!
    let videoOutput:AVCaptureVideoDataOutput!
    var supportsFullYUVRange:Bool = false
    let captureAsYUV:Bool
    let yuvConversionShader:ShaderProgram?
    
    public var runBenchmark:Bool = false
    var numberOfFramesCaptured = 0
    var totalFrameTimeDuringCapture:Double = 0.0


    public init(sessionPreset:String, cameraDevice:AVCaptureDevice? = nil, orientation:ImageOrientation = .Portrait, captureAsYUV:Bool = true) throws {
        self.inputCamera = cameraDevice ?? AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        self.orientation = orientation
        self.captureAsYUV = captureAsYUV
        
        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()

        do {
            self.videoInput = try AVCaptureDeviceInput(device:inputCamera)
        } catch {
            self.videoInput = nil
            self.videoOutput = nil
            self.yuvConversionShader = nil
            super.init()
            throw error
        }
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        }
        
        // Add the video frame output
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = false
        
        if captureAsYUV {
            supportsFullYUVRange = false
            let supportedPixelFormats = videoOutput.availableVideoCVPixelFormatTypes
            for currentPixelFormat in supportedPixelFormats {
                if ((currentPixelFormat as! NSNumber).intValue == Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)) {
                    supportsFullYUVRange = true
                }
            }
            
            if (supportsFullYUVRange) {
                yuvConversionShader = crashOnShaderCompileFailure("Camera"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(2), fragmentShader:YUVConversionFullRangeFragmentShader)}
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey:NSNumber(int:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
            } else {
                yuvConversionShader = crashOnShaderCompileFailure("Camera"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(2), fragmentShader:YUVConversionVideoRangeFragmentShader)}
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey:NSNumber(int:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange))]
            }
        } else {
            yuvConversionShader = nil
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey:NSNumber(int:Int32(kCVPixelFormatType_32BGRA))]
        }

        if (captureSession.canAddOutput(videoOutput)) {
            captureSession.addOutput(videoOutput)
        }
        captureSession.sessionPreset = sessionPreset
        captureSession.commitConfiguration()

        super.init()
    }
    
    public func captureOutput(captureOutput:AVCaptureOutput!, didOutputSampleBuffer sampleBuffer:CMSampleBuffer!, fromConnection connection:AVCaptureConnection!) {
        sharedImageProcessingContext.makeCurrentContext()
        let startTime = CFAbsoluteTimeGetCurrent()

        let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        let cameraFramebuffer:Framebuffer
        
        CVPixelBufferLockBaseAddress(cameraFrame, 0)
        if (captureAsYUV) {
            let luminanceFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:self.orientation, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:true)
            luminanceFramebuffer.lock()
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), luminanceFramebuffer.texture)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(bufferWidth), GLsizei(bufferHeight), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0))

            let chrominanceFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:self.orientation, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:true)
            chrominanceFramebuffer.lock()
            glActiveTexture(GLenum(GL_TEXTURE1))
            glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceFramebuffer.texture)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE_ALPHA, GLsizei(bufferWidth / 2), GLsizei(bufferHeight / 2), 0, GLenum(GL_LUMINANCE_ALPHA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1))

            cameraFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:false)
            
            let conversionMatrix:Matrix3x3
            if (supportsFullYUVRange) {
                conversionMatrix = colorConversionMatrix601FullRangeDefault
            } else {
                conversionMatrix = colorConversionMatrix601Default
            }
            convertYUVToRGB(shader:yuvConversionShader!, luminanceFramebuffer:luminanceFramebuffer, chrominanceFramebuffer:chrominanceFramebuffer, resultFramebuffer:cameraFramebuffer, colorConversionMatrix:conversionMatrix)
        } else {
            cameraFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:self.orientation, size:GLSize(width:GLint(bufferWidth), height:GLint(bufferHeight)), textureOnly:true)
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), cameraFramebuffer.texture)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(bufferWidth), GLsizei(bufferHeight), 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(cameraFrame))
        }
        CVPixelBufferUnlockBaseAddress(cameraFrame, 0)
        
        cameraFramebuffer.timingStyle = .VideoFrame(timestamp:Timestamp(currentTime))
        updateTargetsWithFramebuffer(cameraFramebuffer)
        
        if runBenchmark {
            let currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime)
            numberOfFramesCaptured += 1
            totalFrameTimeDuringCapture += currentFrameTime
            print("Average frame time : \(1000.0 * totalFrameTimeDuringCapture / Double(numberOfFramesCaptured)) ms")
            print("Current frame time : \(1000.0 * currentFrameTime) ms")
        }
    }

    public func startCapture() {
        // Moved this from init() in a first attempt at avoiding some issues
        videoOutput.setSampleBufferDelegate(self, queue:dispatch_get_main_queue())

        if (!captureSession.running) {
            captureSession.startRunning()
        }
    }
    
    public func stopCapture() {
        if (!captureSession.running) {
            captureSession.stopRunning()
        }
    }
}
