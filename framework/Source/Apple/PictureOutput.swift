#if canImport(OpenGL)
import OpenGL.GL3
public typealias PlatformImageType = NSImage
#else
import OpenGLES
public typealias PlatformImageType = UIImage
#endif

#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif

public enum PictureFileFormat {
    case png
    case jpeg
}

public class PictureOutput: ImageConsumer {
    public var encodedImageAvailableCallback:((Data) -> ())?
    public var encodedImageFormat:PictureFileFormat = .png
    public var imageAvailableCallback:((PlatformImageType) -> ())?
    public var onlyCaptureNextFrame:Bool = true
    public var keepImageAroundForSynchronousCapture:Bool = false
    var storedFramebuffer:Framebuffer?
    
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    var url:URL!
    
    public init() {
    }
    
    deinit {
    }
    
    public func saveNextFrameToURL(_ url:URL, format:PictureFileFormat) {
        onlyCaptureNextFrame = true
        encodedImageFormat = format
        self.url = url // Create an intentional short-term retain cycle to prevent deallocation before next frame is captured
        encodedImageAvailableCallback = {imageData in
            do {
                try imageData.write(to: self.url, options:.atomic)
            } catch {
                // TODO: Handle this better
                print("WARNING: Couldn't save image with error:\(error)")
            }
        }
    }
    
    // TODO: Replace with texture caches
    func cgImageFromFramebuffer(_ framebuffer:Framebuffer) -> CGImage {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:framebuffer.size)
        renderFramebuffer.lock()
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.red)
        renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:ShaderUniformSettings(), vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.noRotation)])
        framebuffer.unlock()
        
        let imageByteSize = Int(framebuffer.size.width * framebuffer.size.height * 4)
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: imageByteSize)
        glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        renderFramebuffer.unlock()
        guard let dataProvider = CGDataProvider(dataInfo:nil, data:data, size:imageByteSize, releaseData: dataProviderReleaseCallback) else {fatalError("Could not allocate a CGDataProvider")}
        let defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB()
        return CGImage(width:Int(framebuffer.size.width), height:Int(framebuffer.size.height), bitsPerComponent:8, bitsPerPixel:32, bytesPerRow:4 * Int(framebuffer.size.width), space:defaultRGBColorSpace, bitmapInfo:CGBitmapInfo() /*| CGImageAlphaInfo.Last*/, provider:dataProvider, decode:nil, shouldInterpolate:false, intent:.defaultIntent)!
    }
    
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        if keepImageAroundForSynchronousCapture {
            storedFramebuffer?.unlock()
            storedFramebuffer = framebuffer
        }
        
        if let imageCallback = imageAvailableCallback {
            let cgImageFromBytes = cgImageFromFramebuffer(framebuffer)
            
            // TODO: Let people specify orientations
#if canImport(UIKit)
            let image = UIImage(cgImage:cgImageFromBytes, scale:1.0, orientation:.up)
#else
            let image = NSImage(cgImage:cgImageFromBytes, size:NSZeroSize)
#endif
            
            imageCallback(image)
            
            if onlyCaptureNextFrame {
                imageAvailableCallback = nil
            }
        }
        
        if let imageCallback = encodedImageAvailableCallback {
            let cgImageFromBytes = cgImageFromFramebuffer(framebuffer)
            let imageData:Data
            
#if canImport(UIKit)
            let image = UIImage(cgImage:cgImageFromBytes, scale:1.0, orientation:.up)
            switch encodedImageFormat {
                case .png: imageData = UIImagePNGRepresentation(image)! // TODO: Better error handling here
                case .jpeg: imageData = UIImageJPEGRepresentation(image, 0.8)! // TODO: Be able to set image quality
            }
#else
            let bitmapRepresentation = NSBitmapImageRep(cgImage:cgImageFromBytes)
            switch encodedImageFormat {
                case .png: imageData = bitmapRepresentation.representation(using: .png, properties: [NSBitmapImageRep.PropertyKey(rawValue: ""):""])!
                case .jpeg: imageData = bitmapRepresentation.representation(using: .jpeg, properties: [NSBitmapImageRep.PropertyKey(rawValue: ""):""])!
            }
#endif

            imageCallback(imageData)
            
            if onlyCaptureNextFrame {
                encodedImageAvailableCallback = nil
            }
        }
    }
    
#if canImport(UIKit)
    public func synchronousImageCapture() -> UIImage {
        var outputImage:UIImage!
        sharedImageProcessingContext.runOperationSynchronously{
            guard let currentFramebuffer = storedFramebuffer else { fatalError("Synchronous access requires keepImageAroundForSynchronousCapture to be set to true") }
            
            let cgImageFromBytes = cgImageFromFramebuffer(currentFramebuffer)
            outputImage = UIImage(cgImage:cgImageFromBytes, scale:1.0, orientation:.up)
        }
        
        return outputImage
    }
#endif
}

public extension ImageSource {
    func saveNextFrameToURL(_ url:URL, format:PictureFileFormat) {
        let pictureOutput = PictureOutput()
        pictureOutput.saveNextFrameToURL(url, format:format)
        self --> pictureOutput
    }
}

public extension PlatformImageType {
    func filterWithOperation<T:ImageProcessingOperation>(_ operation:T) -> PlatformImageType {
        return filterWithPipeline{input, output in
            input --> operation --> output
        }
    }
    
    func filterWithPipeline(_ pipeline:(PictureInput, PictureOutput) -> ()) -> PlatformImageType {
        var outputImage:PlatformImageType?
        let picture = PictureInput(image:self)
        let pictureOutput = PictureOutput()
        pictureOutput.onlyCaptureNextFrame = true
        pictureOutput.imageAvailableCallback = {image in
            outputImage = image
        }
        pipeline(picture, pictureOutput)
        picture.processImage(synchronously:true)
        return outputImage!
    }
}

// Why are these flipped in the callback definition?
func dataProviderReleaseCallback(_ context:UnsafeMutableRawPointer?, data:UnsafeRawPointer, size:Int) {
    data.deallocate()
}
