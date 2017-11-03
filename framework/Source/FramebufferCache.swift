#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL3
#endif
#endif

// TODO: Add mechanism to purge framebuffers on low memory

public class FramebufferCache {
    var framebufferCache = [Int64:[Framebuffer.Core]]()
    let context:OpenGLContext
    
    init(context:OpenGLContext) {
        self.context = context
    }
    
    public func requestFramebufferWithProperties(orientation:ImageOrientation, size:GLSize, textureOnly:Bool = false, minFilter:Int32 = GL_LINEAR, magFilter:Int32 = GL_LINEAR, wrapS:Int32 = GL_CLAMP_TO_EDGE, wrapT:Int32 = GL_CLAMP_TO_EDGE, internalFormat:Int32 = GL_RGBA, format:Int32 = GL_BGRA, type:Int32 = GL_UNSIGNED_BYTE, stencil:Bool = false) -> Framebuffer {
        let hash = hashForFramebufferWithProperties(orientation:orientation, size:size, textureOnly:textureOnly, minFilter:minFilter, magFilter:magFilter, wrapS:wrapS, wrapT:wrapT, internalFormat:internalFormat, format:format, type:type, stencil:stencil)
        let core:Framebuffer.Core
        if ((framebufferCache[hash]?.count ?? -1) > 0) {
//            print("Restoring previous framebuffer")
            core = framebufferCache[hash]!.removeLast()
            core.orientation = orientation
        } else {
            do {
                debugPrint("Generating new framebuffer at size: \(size)")

                core = try Framebuffer.Core(context:context, orientation:orientation, size:size, textureOnly:textureOnly, minFilter:minFilter, magFilter:magFilter, wrapS:wrapS, wrapT:wrapT, internalFormat:internalFormat, format:format, type:type, stencil:stencil)
                core.cache = self
            } catch {
                fatalError("Could not create a framebuffer of the size (\(size.width), \(size.height)), error: \(error)")
            }
        }
        return Framebuffer(with:core)
    }
    
    public func purgeAllUnassignedFramebuffers() {
        framebufferCache.removeAll()
    }
    
    internal func returnToCache(_ core:Framebuffer.Core) {
//        print("Returning to cache: \(framebuffer)")
        context.runOperationSynchronously{
            if (self.framebufferCache[core.hash] != nil) {
                self.framebufferCache[core.hash]!.append(core)
            } else {
                self.framebufferCache[core.hash] = [core]
            }
        }
    }
}

