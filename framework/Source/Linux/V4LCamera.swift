#if GLES
import COpenGLES.gles2
#else
import COpenGL
#endif
import CVideo4Linux
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
	
    public init(devicePath:String = "/dev/video0", size:Size) {
        self.devicePath = devicePath
        self.size = size
		
        device = v4l2_open_swift(devicePath, O_RDWR, 0) // Maybe switch to O_RDWR | O_NONBLOCK with the ability to kick out if there's no new frame
        print("Device: \(device)")
        
        var capabilities:v4l2_capability = v4l2_capability()
        
        var format:v4l2_format = v4l2_generate_YUV420_format(Int32(round(Double(size.width))), Int32(round(Double(size.height))))
        
        print("Device resolution: \(format.fmt.pix.width) x \(format.fmt.pix.height)")
        
        let result = v4l2_ioctl_S_FMT(device, &format)
        let result2 = v4l2_ioctl_QUERYCAP(device, &capabilities)
        print("Format: \(format), result: \(result)")
        
        print("Capabilities: \(capabilities), result: \(result2)")
    }
    
    deinit {
        v4l2_close(device)
    }
    
    public func startCapture() {
        let numberOfBuffers:Int32  = 2
        let requestBuffers = v4l2_request_buffer_size(device, numberOfBuffers)
        print("Request buffers: \(requestBuffers)")
        
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

        let luminanceFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:GLSize(size), textureOnly:true)

        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), luminanceFramebuffer.texture)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_LUMINANCE, GLsizei(round(Double(size.width))), GLsizei(round(Double(size.height))), 0, GLenum(GL_LUMINANCE), GLenum(GL_UNSIGNED_BYTE), buffers[Int(currentBuffer)].start)
        
        v4l2_enqueue_buffer(device, currentBuffer)
        if (currentBuffer == 0) {
            currentBuffer = 1
        } else {
            currentBuffer = 0
        }
        
        updateTargetsWithFramebuffer(luminanceFramebuffer)
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
}
