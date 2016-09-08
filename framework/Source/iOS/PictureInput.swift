import OpenGLES
import UIKit

public class PictureInput: ImageSource {
    public let targets = TargetContainer()
    var imageFramebuffer:Framebuffer!
    var hasProcessedImage:Bool = false
    
    public init(image:CGImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        // TODO: Dispatch this whole thing asynchronously to move image loading off main thread
        let widthOfImage = GLint(image.width)
        let heightOfImage = GLint(image.height)
        
        // If passed an empty image reference, CGContextDrawImage will fail in future versions of the SDK.
        guard((widthOfImage > 0) && (heightOfImage > 0)) else { fatalError("Tried to pass in a zero-sized image") }

        var widthToUseForTexture = widthOfImage
        var heightToUseForTexture = heightOfImage
        var shouldRedrawUsingCoreGraphics = false
        
        // For now, deal with images larger than the maximum texture size by resizing to be within that limit
        let scaledImageSizeToFitOnGPU = GLSize(sharedImageProcessingContext.sizeThatFitsWithinATextureForSize(Size(width:Float(widthOfImage), height:Float(heightOfImage))))
        if ((scaledImageSizeToFitOnGPU.width != widthOfImage) && (scaledImageSizeToFitOnGPU.height != heightOfImage)) {
            widthToUseForTexture = scaledImageSizeToFitOnGPU.width
            heightToUseForTexture = scaledImageSizeToFitOnGPU.height
            shouldRedrawUsingCoreGraphics = true
        }
        
        if (smoothlyScaleOutput) {
            // In order to use mipmaps, you need to provide power-of-two textures, so convert to the next largest power of two and stretch to fill
            let powerClosestToWidth = ceil(log2(Float(widthToUseForTexture)))
            let powerClosestToHeight = ceil(log2(Float(heightToUseForTexture)))
            
            widthToUseForTexture = GLint(round(pow(2.0, powerClosestToWidth)))
            heightToUseForTexture = GLint(round(pow(2.0, powerClosestToHeight)))
            shouldRedrawUsingCoreGraphics = true
        }
        
        var imageData:UnsafeMutablePointer<GLubyte>!
        var dataFromImageDataProvider:CFData!
        var format = GL_BGRA
        
        if (!shouldRedrawUsingCoreGraphics) {
            /* Check that the memory layout is compatible with GL, as we cannot use glPixelStore to
            * tell GL about the memory layout with GLES.
            */
            if ((image.bytesPerRow != image.width * 4) || (image.bitsPerPixel != 32) || (image.bitsPerComponent != 8))
            {
                shouldRedrawUsingCoreGraphics = true
            } else {
                /* Check that the bitmap pixel format is compatible with GL */
                let bitmapInfo = image.bitmapInfo
                if (bitmapInfo.contains(.floatComponents)) {
                    /* We don't support float components for use directly in GL */
                    shouldRedrawUsingCoreGraphics = true
                } else {
                    let alphaInfo = CGImageAlphaInfo(rawValue:bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue)
                    if (bitmapInfo.contains(.byteOrder32Little)) {
                        /* Little endian, for alpha-first we can use this bitmap directly in GL */
                        if ((alphaInfo != CGImageAlphaInfo.premultipliedFirst) && (alphaInfo != CGImageAlphaInfo.first) && (alphaInfo != CGImageAlphaInfo.noneSkipFirst)) {
                                shouldRedrawUsingCoreGraphics = true
                        }
                    } else if ((bitmapInfo.contains(CGBitmapInfo())) || (bitmapInfo.contains(.byteOrder32Big))) {
                        /* Big endian, for alpha-last we can use this bitmap directly in GL */
                        if ((alphaInfo != CGImageAlphaInfo.premultipliedLast) && (alphaInfo != CGImageAlphaInfo.last) && (alphaInfo != CGImageAlphaInfo.noneSkipLast)) {
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
            imageData = UnsafeMutablePointer<GLubyte>.allocate(capacity:Int(widthToUseForTexture * heightToUseForTexture) * 4)

            let genericRGBColorspace = CGColorSpaceCreateDeviceRGB()
            
            let imageContext = CGContext(data: imageData, width: Int(widthToUseForTexture), height: Int(heightToUseForTexture), bitsPerComponent: 8, bytesPerRow: Int(widthToUseForTexture) * 4, space: genericRGBColorspace,  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
            //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
            imageContext?.draw(image, in:CGRect(x:0.0, y:0.0, width:CGFloat(widthToUseForTexture), height:CGFloat(heightToUseForTexture)))
        } else {
            // Access the raw image bytes directly
            dataFromImageDataProvider = image.dataProvider?.data
            imageData = UnsafeMutablePointer<GLubyte>(mutating:CFDataGetBytePtr(dataFromImageDataProvider))
        }
        
        sharedImageProcessingContext.runOperationSynchronously{
            do {
                // TODO: Alter orientation based on metadata from photo
                self.imageFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:orientation, size:GLSize(width:widthToUseForTexture, height:heightToUseForTexture), textureOnly:true)
            } catch {
                fatalError("ERROR: Unable to initialize framebuffer of size (\(widthToUseForTexture), \(heightToUseForTexture)) with error: \(error)")
            }
            
            glBindTexture(GLenum(GL_TEXTURE_2D), self.imageFramebuffer.texture)
            if (smoothlyScaleOutput) {
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
            }
            
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, widthToUseForTexture, heightToUseForTexture, 0, GLenum(format), GLenum(GL_UNSIGNED_BYTE), imageData)
            
            if (smoothlyScaleOutput) {
                glGenerateMipmap(GLenum(GL_TEXTURE_2D))
            }
            glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        }
        
        if (shouldRedrawUsingCoreGraphics) {
            imageData.deallocate(capacity:Int(widthToUseForTexture * heightToUseForTexture) * 4)
        }
    }
    
    public convenience init(image:UIImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        self.init(image:image.cgImage!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }

    public convenience init(imageName:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        guard let image = UIImage(named:imageName) else { fatalError("No such image named: \(imageName) in your application bundle") }
        self.init(image:image.cgImage!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }

    public func processImage(synchronously:Bool = false) {
        if synchronously {
            sharedImageProcessingContext.runOperationSynchronously{
                self.updateTargetsWithFramebuffer(self.imageFramebuffer)
                self.hasProcessedImage = true
            }
        } else {
            sharedImageProcessingContext.runOperationAsynchronously{
                self.updateTargetsWithFramebuffer(self.imageFramebuffer)
                self.hasProcessedImage = true
            }
        }
    }
    
    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        if hasProcessedImage {
            imageFramebuffer.lock()
            target.newFramebufferAvailable(imageFramebuffer, fromSourceIndex:atIndex)
        }
    }
}
