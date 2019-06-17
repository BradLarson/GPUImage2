#if canImport(COpenGL)
import COpenGL
#else
import COpenGLES.gles2
#endif

// apt-get install libgd-dev
import Foundation
import SwiftGD

public class PictureInput: ImageSource {
    public let targets = TargetContainer()
    var imageFramebuffer:Framebuffer!
    var hasProcessedImage:Bool = false

    public init?(path:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        let location = URL(fileURLWithPath: path)
        guard let image = Image(url: location) else { return nil }
        let bitmapImage = try! image.export(as:.bmp(compression:false))
        let widthToUseForTexture = GLint(image.size.width)
        let heightToUseForTexture = GLint(image.size.height)

        sharedImageProcessingContext.runOperationSynchronously{
            do {
                self.imageFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:orientation, size:GLSize(width:widthToUseForTexture, height:heightToUseForTexture), textureOnly:true)
                print("Framebuffer created")
            } catch {
                fatalError("ERROR: Unable to initialize framebuffer of size (\(widthToUseForTexture), \(heightToUseForTexture)) with error: \(error)")
            }
            
            glBindTexture(GLenum(GL_TEXTURE_2D), self.imageFramebuffer.texture)
            // if (smoothlyScaleOutput) {
            //     glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
            // }
            bitmapImage.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
                let imageData = UnsafeRawPointer(u8Ptr) + 54
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, widthToUseForTexture, heightToUseForTexture, 0, GLenum(GL_RGB), GLenum(GL_UNSIGNED_BYTE), imageData)
            }
            
            // if (smoothlyScaleOutput) {
            //     glGenerateMipmap(GLenum(GL_TEXTURE_2D))
            // }
            glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        }
    }

    public func processImage(synchronously:Bool = false) {
        if synchronously {
            sharedImageProcessingContext.runOperationSynchronously{
                sharedImageProcessingContext.makeCurrentContext()
                self.updateTargetsWithFramebuffer(self.imageFramebuffer)
                self.hasProcessedImage = true
            }
        } else {
            sharedImageProcessingContext.runOperationAsynchronously{
                sharedImageProcessingContext.makeCurrentContext()
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
