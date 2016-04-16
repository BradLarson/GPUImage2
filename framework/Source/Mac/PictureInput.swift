import OpenGL.GL3
import Cocoa

public class PictureInput: ImageSource {
    public let targets = TargetContainer()
    var imageFramebuffer:Framebuffer!
    
    public init(image:CGImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .Portrait) {
        // TODO: Dispatch this whole thing asynchronously to move image loading off main thread
        let widthOfImage = GLint(CGImageGetWidth(image))
        let heightOfImage = GLint(CGImageGetHeight(image))
        
        // If passed an empty image reference, CGContextDrawImage will fail in future versions of the SDK.
        guard((widthOfImage > 0) && (heightOfImage > 0)) else { fatalError("Tried to pass in a zero-sized image") }

        var widthToUseForTexture = widthOfImage
        var heightToUseForTexture = heightOfImage
        var shouldRedrawUsingCoreGraphics = false
        
        // For now, deal with images larger than the maximum texture size by resizing to be within that limit
        // TODO: Fix this
//        CGSize scaledImageSizeToFitOnGPU = [GPUImageContext sizeThatFitsWithinATextureForSize:pixelSizeOfImage];
//        if (!CGSizeEqualToSize(scaledImageSizeToFitOnGPU, pixelSizeOfImage))
//        {
//            pixelSizeOfImage = scaledImageSizeToFitOnGPU;
//            pixelSizeToUseForTexture = pixelSizeOfImage;
//            shouldRedrawUsingCoreGraphics = YES;
//        }
        
        if (smoothlyScaleOutput) {
            // In order to use mipmaps, you need to provide power-of-two textures, so convert to the next largest power of two and stretch to fill
            let powerClosestToWidth = ceil(log2(Float(widthToUseForTexture)))
            let powerClosestToHeight = ceil(log2(Float(heightToUseForTexture)))
            
            widthToUseForTexture = GLint(round(pow(2.0, powerClosestToWidth)))
            heightToUseForTexture = GLint(round(pow(2.0, powerClosestToHeight)))
            shouldRedrawUsingCoreGraphics = true
        }
        
        var imageData:UnsafeMutablePointer<GLubyte>!
        var dataFromImageDataProvider:CFDataRef!
        var format = GL_BGRA
        
        if (!shouldRedrawUsingCoreGraphics) {
            /* Check that the memory layout is compatible with GL, as we cannot use glPixelStore to
            * tell GL about the memory layout with GLES.
            */
            if ((CGImageGetBytesPerRow(image) != CGImageGetWidth(image) * 4) || (CGImageGetBitsPerPixel(image) != 32) || (CGImageGetBitsPerComponent(image) != 8))
            {
                shouldRedrawUsingCoreGraphics = true
            } else {
                /* Check that the bitmap pixel format is compatible with GL */
                let bitmapInfo = CGImageGetBitmapInfo(image)
                if (bitmapInfo.contains(.FloatComponents)) {
                    /* We don't support float components for use directly in GL */
                    shouldRedrawUsingCoreGraphics = true
                } else {
                    let alphaInfo = CGImageAlphaInfo(rawValue:bitmapInfo.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue)
                    if (bitmapInfo.contains(.ByteOrder32Little)) {
                        /* Little endian, for alpha-first we can use this bitmap directly in GL */
                        if ((alphaInfo != CGImageAlphaInfo.PremultipliedFirst) && (alphaInfo != CGImageAlphaInfo.First) && (alphaInfo != CGImageAlphaInfo.NoneSkipFirst)) {
                                shouldRedrawUsingCoreGraphics = true
                        }
                    } else if ((bitmapInfo.contains(.ByteOrderDefault)) || (bitmapInfo.contains(.ByteOrder32Big))) {
                        /* Big endian, for alpha-last we can use this bitmap directly in GL */
                        if ((alphaInfo != CGImageAlphaInfo.PremultipliedLast) && (alphaInfo != CGImageAlphaInfo.Last) && (alphaInfo != CGImageAlphaInfo.NoneSkipLast)) {
                                shouldRedrawUsingCoreGraphics = true
                        } else {
                            /* Can access directly using GL_RGBA pixel format */
                            format = GL_RGBA
                        }
                    }
                }
            }
        }
        
        //    CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();
        
        if (shouldRedrawUsingCoreGraphics) {
            // For resized or incompatible image: redraw
            imageData = UnsafeMutablePointer<GLubyte>.alloc(Int(widthToUseForTexture * heightToUseForTexture) * 4)

            let genericRGBColorspace = CGColorSpaceCreateDeviceRGB()
            
            let imageContext = CGBitmapContextCreate(imageData, Int(widthToUseForTexture), Int(heightToUseForTexture), 8, Int(widthToUseForTexture) * 4, genericRGBColorspace,  CGImageAlphaInfo.PremultipliedFirst.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue)
            //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
            CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, CGFloat(widthToUseForTexture), CGFloat(heightToUseForTexture)), image)
        } else {
            // Access the raw image bytes directly
            dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(image))
            imageData = UnsafeMutablePointer<GLubyte>(CFDataGetBytePtr(dataFromImageDataProvider))
        }
        
        sharedImageProcessingContext.makeCurrentContext()
        do {
            imageFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:orientation, size:GLSize(width:widthToUseForTexture, height:heightToUseForTexture), textureOnly:true)
            imageFramebuffer.timingStyle = .StillImage
        } catch {
            fatalError("ERROR: Unable to initialize framebuffer of size (\(widthToUseForTexture), \(heightToUseForTexture)) with error: \(error)")
        }

        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), imageFramebuffer.texture)
        if (smoothlyScaleOutput) {
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
        }

        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, widthToUseForTexture, heightToUseForTexture, 0, GLenum(format), GLenum(GL_UNSIGNED_BYTE), imageData)
            
        if (smoothlyScaleOutput) {
            glGenerateMipmap(GLenum(GL_TEXTURE_2D))
        }
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        if (shouldRedrawUsingCoreGraphics) {
            imageData.dealloc(Int(widthToUseForTexture * heightToUseForTexture) * 4)
        }
    }
    
    public convenience init(image:NSImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .Portrait) {
        self.init(image:image.CGImageForProposedRect(nil, context:nil, hints:nil)!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }

    public convenience init(imageName:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .Portrait) {
        guard let image = NSImage(named:imageName) else { fatalError("No such image named: \(imageName) in your application bundle") }
        self.init(image:image.CGImageForProposedRect(nil, context:nil, hints:nil)!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }

//    convenience init(url:NSURL, smoothlyScaleOutput:Bool = false) {
//        
//    }

    public func processImage() {
        updateTargetsWithFramebuffer(imageFramebuffer)
    }
}