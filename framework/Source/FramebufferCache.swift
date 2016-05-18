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

class FramebufferCache {
    var framebufferCache = [String:[Framebuffer]]()
    let context:OpenGLContext
    
    init(context:OpenGLContext) {
        self.context = context
    }
    
    func requestFramebufferWithProperties(orientation orientation:ImageOrientation, size:GLSize, textureOnly:Bool = false, minFilter:Int32 = GL_LINEAR, magFilter:Int32 = GL_LINEAR, wrapS:Int32 = GL_CLAMP_TO_EDGE, wrapT:Int32 = GL_CLAMP_TO_EDGE, internalFormat:Int32 = GL_RGBA, format:Int32 = GL_BGRA, type:Int32 = GL_UNSIGNED_BYTE, stencil:Bool = false) -> Framebuffer {
        let hash = hashForFramebufferWithProperties(orientation:orientation, size:size, textureOnly:textureOnly, minFilter:minFilter, magFilter:magFilter, wrapS:wrapS, wrapT:wrapT, internalFormat:internalFormat, format:format, type:type, stencil:stencil)
        let framebuffer:Framebuffer
        if (framebufferCache[hash]?.count > 0) {
//            print("Restoring previous framebuffer")
            framebuffer = framebufferCache[hash]!.removeLast()
        } else {
            do {
                debugPrint("Generating new framebuffer at size: \(size)")

                framebuffer = try Framebuffer(context:context, orientation:orientation, size:size, textureOnly:textureOnly, minFilter:minFilter, magFilter:magFilter, wrapS:wrapS, wrapT:wrapT, internalFormat:internalFormat, format:format, type:type, stencil:stencil)
                framebuffer.cache = self
            } catch {
                fatalError("Could not create a framebuffer of the size (\(size.width), \(size.height))")
            }
        }
        return framebuffer
    }
    
    func returnFramebufferToCache(framebuffer:Framebuffer) {
//        print("Returning to cache: \(framebuffer)")
        context.runOperationSynchronously{
            if (self.framebufferCache[framebuffer.hash] != nil) {
                self.framebufferCache[framebuffer.hash]!.append(framebuffer)
            } else {
                self.framebufferCache[framebuffer.hash] = [framebuffer]
            }
        }
    }
    
    func purgeAllUnassignedFramebuffers() {
        framebufferCache.removeAll()
    }
}

