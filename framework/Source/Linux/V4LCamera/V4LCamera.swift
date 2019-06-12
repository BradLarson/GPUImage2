#if canImport(COpenGL)
import COpenGL
#endif

#if canImport(COpenGLES)
import COpenGLES.gles2
#endif

import GPUImage
import CVideo4Linux
import V4LSupplement
import Glibc
import Foundation

public class V4LCamera:ImageSource {
    public let targets = TargetContainer()
    
    let devicePath:String
    let device:Int32
    let size:Size
    var cameraOutputTexture:GLuint = 0
    var buffers = [buffer]()
    var currentBuffer:Int32 = 0
    
    public var runBenchmark:Bool = false
    var numberOfFramesCaptured = 0
    var totalFrameTimeDuringCapture:Double = 0.0
    let yuvConversionShader:ShaderProgram?
    
    public init(devicePath:String = "/dev/video0", size:Size) {
        self.devicePath = devicePath
        self.size = size
        
        device = v4l2_open_swift(devicePath, O_RDWR, 0) // Maybe switch to O_RDWR | O_NONBLOCK with the ability to kick out if there's no new frame
        
        var capabilities:v4l2_capability = v4l2_capability()
        
        var format:v4l2_format = v4l2_generate_YUV420_format(Int32(round(Double(size.width))), Int32(round(Double(size.height))))
        
        v4l2_ioctl_S_FMT(device, &format)
        v4l2_ioctl_QUERYCAP(device, &capabilities)
        
        yuvConversionShader = crashOnShaderCompileFailure("V4LCamera"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(3), fragmentShader:YUVConversionFullRangeUVPlanarFragmentShader)}
    }
    
    deinit {
        v4l2_close(device)
    }
    
    public func startCapture() {
        let numberOfBuffers:Int32  = 2
        v4l2_request_buffer_size(device, numberOfBuffers)
        
        for index in 0..<numberOfBuffers {
            buffers.append(v4l2_generate_buffer(device, index))
        }
        
        v4l2_streamon(device)
        
        // Enqueue initial buffers
        for index in 0..<numberOfBuffers {
            v4l2_enqueue_buffer(device, index)
        }
    }
    
    public func grabFrame() {
        v4l2_dequeue_buffer(device, currentBuffer)
        
        let startTime = NSDate()
        
        let luminanceFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:GLSize(size), textureOnly:true)
        luminanceFramebuffer.lock()
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), luminanceFramebuffer.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(round(Double(size.width))), GLsizei(round(Double(size.height))), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), buffers[Int(currentBuffer)].start)
        
        // YUV 420 chrominance is split into two planes in V4L
        let chrominanceFramebuffer1 = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:GLSize(width:GLint(round(Double(size.width) / 2.0)), height:GLint(round(Double(size.height) / 2.0))), textureOnly:true)
        chrominanceFramebuffer1.lock()
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceFramebuffer1.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(round(Double(size.width) / 2.0)), GLsizei(round(Double(size.height) / 2.0)), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), buffers[Int(currentBuffer)].start + (Int(round(Double(size.width))) * Int(round(Double(size.height)))))
        
        let chrominanceFramebuffer2 = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:GLSize(width:GLint(round(Double(size.width) / 2.0)), height:GLint(round(Double(size.height) / 2.0))), textureOnly:true)
        chrominanceFramebuffer2.lock()
        
        glActiveTexture(GLenum(GL_TEXTURE2))
        glBindTexture(GLenum(GL_TEXTURE_2D), chrominanceFramebuffer2.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(round(Double(size.width) / 2.0)), GLsizei(round(Double(size.height) / 2.0)), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), buffers[Int(currentBuffer)].start + (Int(round(Double(size.width * size.height + size.width * size.height / 4.0)))))
        
        v4l2_enqueue_buffer(device, currentBuffer)
        if (currentBuffer == 0) {
            currentBuffer = 1
        } else {
            currentBuffer = 0
        }
        
        let cameraFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:luminanceFramebuffer.sizeForTargetOrientation(.portrait), textureOnly:false)
        
        let conversionMatrix = colorConversionMatrix601FullRangeDefault
        convertYUVToRGB(shader:self.yuvConversionShader!, luminanceFramebuffer:luminanceFramebuffer, chrominanceFramebuffer:chrominanceFramebuffer1, secondChrominanceFramebuffer:chrominanceFramebuffer2, resultFramebuffer:cameraFramebuffer, colorConversionMatrix:conversionMatrix)
        
        updateTargetsWithFramebuffer(cameraFramebuffer)
        
        if runBenchmark {
            let elapsedTime = -startTime.timeIntervalSinceNow
            print("Current: \(elapsedTime * 1000.0) ms")
            numberOfFramesCaptured += 1
            totalFrameTimeDuringCapture += elapsedTime
            print("Average: \(1000.0 * totalFrameTimeDuringCapture / Double(numberOfFramesCaptured))")
        }
    }
    
    func stopCapture() {
        v4l2_streamoff(device)
        
        for buffer in buffers {
            v4l2_munmap(buffer.start, buffer.length)
        }
    }

    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        // Not needed for camera inputs
    }
}
