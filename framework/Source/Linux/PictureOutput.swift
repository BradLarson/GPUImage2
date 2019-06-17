#if canImport(COpenGL)
import COpenGL
#else
import COpenGLES.gles2
#endif

// apt-get install libgd-dev
import Foundation
import lodepng

public enum PictureFileFormat {
    case png
    //case jpeg
}

public class PictureOutput: ImageConsumer {
    // public var encodedImageAvailableCallback:((Data) -> ())?
    public var rawBytesAvailableCallback:((UnsafeMutablePointer<UInt8>, Size) -> ())?
    public var encodedImageFormat:PictureFileFormat = .png
    public var onlyCaptureNextFrame:Bool = true
    public var keepImageAroundForSynchronousCapture:Bool = false
    var storedFramebuffer:Framebuffer?
    
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    //var url:URL!
    
    public init() {
    }
    
    deinit {
    }
    
    public func saveNextFrameToPath(_ path:String, format:PictureFileFormat) {
        onlyCaptureNextFrame = true
        encodedImageFormat = format
        //self.url = url // Create an intentional short-term retain cycle to prevent deallocation before next frame is captured
        // encodedImageAvailableCallback = {imageData in

        rawBytesAvailableCallback = {imageData, imageSize in
            lodepng_encode32_file(path, imageData, UInt32(imageSize.width), UInt32(imageSize.height))

            imageData.deallocate()
        }
    }
    
    // TODO: Replace with texture caches
    func newImageBytesFromFramebuffer(_ framebuffer:Framebuffer) -> (UnsafeMutablePointer<UInt8>, Size) {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:framebuffer.size)
        renderFramebuffer.lock()
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.red)
        renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:ShaderUniformSettings(), vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.flipVertically)])
        framebuffer.unlock()
        
        let imageByteSize = Int(framebuffer.size.width * framebuffer.size.height * 4)
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: imageByteSize)
        let size = Size(framebuffer.size)
        glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), data)
        renderFramebuffer.unlock()
        return (data, size)
    }
    
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        if keepImageAroundForSynchronousCapture {
            storedFramebuffer?.unlock()
            storedFramebuffer = framebuffer
        }
        
//        if let imageCallback = encodedImageAvailableCallback {
        if let imageCallback = rawBytesAvailableCallback {
            let (imageBytes, imageSize) = newImageBytesFromFramebuffer(framebuffer)

            imageCallback(imageBytes, imageSize)
            
            if onlyCaptureNextFrame {
                rawBytesAvailableCallback = nil
            }
        }
    }
}

// public extension ImageSource {
//     func saveNextFrameToURL(_ url:URL, format:PictureFileFormat) {
//         let pictureOutput = PictureOutput()
//         pictureOutput.saveNextFrameToURL(url, format:format)
//         self --> pictureOutput
//     }
// }