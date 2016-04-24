import OpenGL.GL3
import Cocoa

public enum PictureFileFormat {
    case PNG
    case JPEG
}

public class PictureOutput: ImageConsumer {
    public var encodedImageAvailableCallback:(NSData -> ())?
    public var encodedImageFormat:PictureFileFormat = .PNG
    public var imageAvailableCallback:(NSImage -> ())?
    public var onlyCaptureNextFrame:Bool = true
    
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    var url:NSURL!
    
    public init() {
    }
    
    deinit {
        print("Deallocating picture")
    }

    public func saveNextFrameToURL(url:NSURL, format:PictureFileFormat) {
        onlyCaptureNextFrame = true
        encodedImageFormat = format
        self.url = url // Create an intentional short-term retain cycle to prevent deallocation before next frame is captured
        encodedImageAvailableCallback = {imageData in
            do {
                try imageData.writeToURL(self.url, options:.DataWritingAtomic)
            } catch {
                // TODO: Handle this better
                print("WARNING: Couldn't save image with error:\(error)")
            }
        }
    }

    // TODO: Replace with texture caches and a safer capture routine
    func cgImageFromFramebuffer(framebuffer:Framebuffer) -> CGImage {
        let renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:framebuffer.size)
        renderFramebuffer.lock()
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.Red)
        renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:ShaderUniformSettings(), vertices:standardImageVertices, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.NoRotation)])
        framebuffer.unlock()
        
        let imageByteSize = Int(framebuffer.size.width * framebuffer.size.height * 4)
        let data = UnsafeMutablePointer<UInt8>.alloc(imageByteSize)
        glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        renderFramebuffer.unlock()
        let dataProvider = CGDataProviderCreateWithData(nil, data, imageByteSize, dataProviderReleaseCallback)
        let defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB()
        return CGImageCreate(Int(framebuffer.size.width), Int(framebuffer.size.height), 8, 32, 4 * Int(framebuffer.size.width), defaultRGBColorSpace, .ByteOrderDefault /*| CGImageAlphaInfo.Last*/, dataProvider, nil, false, .RenderingIntentDefault)!

    }
    
    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
        if let imageCallback = imageAvailableCallback {
            let cgImageFromBytes = cgImageFromFramebuffer(framebuffer)
            let image = NSImage(CGImage:cgImageFromBytes, size:NSZeroSize)
            
            imageCallback(image)
            
            if onlyCaptureNextFrame {
                encodedImageAvailableCallback = nil
            }
        }
        
        if let imageCallback = encodedImageAvailableCallback {
            let cgImageFromBytes = cgImageFromFramebuffer(framebuffer)
            let bitmapRepresentation = NSBitmapImageRep(CGImage:cgImageFromBytes)
            let imageData:NSData
            switch encodedImageFormat {
                case .PNG: imageData = bitmapRepresentation.representationUsingType(.NSPNGFileType, properties: ["":""])!
                case .JPEG: imageData = bitmapRepresentation.representationUsingType(.NSJPEGFileType, properties: ["":""])!
            }

            imageCallback(imageData)
            
            if onlyCaptureNextFrame {
                encodedImageAvailableCallback = nil
            }
        }
    }
}

public extension ImageSource {
    public func saveNextFrameToURL(url:NSURL, format:PictureFileFormat) {
        let pictureOutput = PictureOutput()
        pictureOutput.saveNextFrameToURL(url, format:format)
        self --> pictureOutput
    }
}

public extension NSImage {
    public func filterWithOperation<T:ImageProcessingOperation>(operation:T) -> NSImage {
        return filterWithPipeline{input, output in
            input --> operation --> output
        }
    }

    public func filterWithPipeline(pipeline:(input:PictureInput, output:PictureOutput) -> ()) -> NSImage {
        let picture = PictureInput(image:self)
        var outputImage:NSImage?
        let pictureOutput = PictureOutput()
        pictureOutput.onlyCaptureNextFrame = true
        pictureOutput.imageAvailableCallback = {image in
            outputImage = image
        }
        pipeline(input:picture, output:pictureOutput)
        picture.processImage(synchronously:true)
        return outputImage!
    }
}

func dataProviderReleaseCallback(pointer:UnsafeMutablePointer<Void>, context:UnsafePointer<Void>, size:Int) {
    pointer.dealloc(size)
}
