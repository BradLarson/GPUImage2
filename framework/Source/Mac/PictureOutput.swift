import OpenGL.GL3
import Cocoa

public enum PictureFileFormat {
    case png
    case jpeg
}

public class PictureOutput: ImageConsumer {
    public var encodedImageAvailableCallback:((Data) -> ())?
    public var encodedImageFormat:PictureFileFormat = .png
    public var imageAvailableCallback:((NSImage) -> ())?
    public var onlyCaptureNextFrame:Bool = true
    
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
// FIXME: Xcode 8 beta 2
                try imageData.write(to: self.url, options:.atomic)
//                try imageData.write(to: self.url, options:NSData.WritingOptions.dataWritingAtomic)
            } catch {
                // TODO: Handle this better
                print("WARNING: Couldn't save image with error:\(error)")
            }
        }
    }

    // TODO: Replace with texture caches and a safer capture routine
    func cgImageFromFramebuffer(_ framebuffer:Framebuffer) -> CGImage {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:framebuffer.size)
        renderFramebuffer.lock()
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.transparent)

        // Need the blending here to enable non-1.0 alpha on output image
        enableAdditiveBlending()
        
        renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:ShaderUniformSettings(), vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.noRotation)])

        disableBlending()
        
        framebuffer.unlock()
        
        let imageByteSize = Int(framebuffer.size.width * framebuffer.size.height * 4)
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity:imageByteSize)
        glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        renderFramebuffer.unlock()
        guard let dataProvider = CGDataProvider(dataInfo: nil, data: data, size: imageByteSize, releaseData: dataProviderReleaseCallback) else {fatalError("Could not create CGDataProvider")}
        let defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB()
        
        return CGImage(width: Int(framebuffer.size.width), height: Int(framebuffer.size.height), bitsPerComponent:8, bitsPerPixel:32, bytesPerRow:4 * Int(framebuffer.size.width), space:defaultRGBColorSpace, bitmapInfo:CGBitmapInfo() /*| CGImageAlphaInfo.Last*/, provider:dataProvider, decode:nil, shouldInterpolate:false, intent:.defaultIntent)!
    }
    
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        if let imageCallback = imageAvailableCallback {
            let cgImageFromBytes = cgImageFromFramebuffer(framebuffer)
            let image = NSImage(cgImage:cgImageFromBytes, size:NSZeroSize)
            
            imageCallback(image)
            
            if onlyCaptureNextFrame {
                imageAvailableCallback = nil
            }
        }
        
        if let imageCallback = encodedImageAvailableCallback {
            let cgImageFromBytes = cgImageFromFramebuffer(framebuffer)
            let bitmapRepresentation = NSBitmapImageRep(cgImage:cgImageFromBytes)
            let imageData:Data
            switch encodedImageFormat {
                case .png: imageData = bitmapRepresentation.representation(using: .PNG, properties: ["":""])!
                case .jpeg: imageData = bitmapRepresentation.representation(using: .JPEG, properties: ["":""])!
            }

            imageCallback(imageData)
            
            if onlyCaptureNextFrame {
                encodedImageAvailableCallback = nil
            }
        }
    }
}

public extension ImageSource {
    public func saveNextFrameToURL(_ url:URL, format:PictureFileFormat) {
        let pictureOutput = PictureOutput()
        pictureOutput.saveNextFrameToURL(url, format:format)
        self --> pictureOutput
    }
}

public extension NSImage {
    public func filterWithOperation<T:ImageProcessingOperation>(_ operation:T) -> NSImage {
        return filterWithPipeline{input, output in
            input --> operation --> output
        }
    }

    public func filterWithPipeline(_ pipeline:(PictureInput, PictureOutput) -> ()) -> NSImage {
        let picture = PictureInput(image:self)
        var outputImage:NSImage?
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
//    UnsafeMutablePointer<UInt8>(data).deallocate(capacity:size)
    // FIXME: Verify this is correct
    data.deallocate(bytes:size, alignedTo:1)
}
