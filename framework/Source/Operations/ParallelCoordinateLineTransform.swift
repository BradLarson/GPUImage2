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

//
//  ParallelCoordinateLineTransform.swift
//  GPUImage-Mac
//
//  Created by Max Cantor on 8/3/16.
//  Copyright © 2016 Sunset Lake Software LLC. All rights reserved.
//

import Foundation

public class ParallelCoordinateLineTransform: BasicOperation {
    var lineCoordinates:UnsafeMutablePointer<GLfloat>?
    let MAX_SCALING_FACTOR: UInt32 = 4
    public init() {
        let fragShader =
            ( sharedImageProcessingContext.deviceSupportsFramebufferReads()
                ? ParallelCoordinateLineTransformFBOReadFragmentShader
                : ParallelCoordinateLineTransformFragmentShader
                )
        super.init(vertexShader: ParallelCoordinateLineTransformVertexShader, fragmentShader: fragShader)
    }
    override func renderFrame() {
        renderToTextureVertices()
    }
    func renderToTextureVertices() {
        guard let framebuffer = inputFramebuffers[0] else {fatalError("Could not get framebuffer orientation for parallel coords")}
        let inputSize = sizeOfInitialStageBasedOnFramebuffer(framebuffer)
        // Making lots of things Ints instead of UInt32 or Int32 so that we can "Freely" access array indices.
        // I dont like it but c'est la vie
        let inputByteSize = Int(inputSize.width * inputSize.height * 4)
        let imageByteWidth = framebuffer.size.width * 4
        let maxLinePairsToRender = (Int(inputSize.width * inputSize.height) / Int(self.MAX_SCALING_FACTOR))
        let lineCoordinates = self.lineCoordinates ??
            UnsafeMutablePointer<GLfloat>.allocate(capacity: Int(maxLinePairsToRender * 8))

        let rawImagePixels = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(inputByteSize))
        glFinish()
        glReadPixels(0, 0, inputSize.width, inputSize.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), rawImagePixels)


//var lineCoordinates = Array<Line>(count: Int(maxLinePairsToRender) * 2, repeatedValue: Line.Segment(p1:Position(0,0),p2:Position(0,0)))
        // Copying from Harris Corner Detector
//        let imageByteSize = Int(framebuffer.size.width * framebuffer.size.height * 4)
//        let inputTextureSize = framebuffer.size

        let startTime = CFAbsoluteTimeGetCurrent()
        let xAspectMultiplier:Float = 1.0
        let yAspectMultiplier:Float = 1.0


        var linePairsToRender:Int = 0
        var currentByte:Int = 0
        var lineStorageIndex:Int = 0

        let maxLineStorageIndex = maxLinePairsToRender * 8 - 8

        var minY:Float = 100
        var maxY:Float = -100
        var minX:Float = 100
        var maxX:Float = -100

        while (currentByte < inputByteSize) {
            let colorByte = rawImagePixels[currentByte]

            if (colorByte > 0) {
                let xCoordinate = Int32(currentByte) % imageByteWidth
                let yCoordinate = Int32(currentByte) / imageByteWidth

                let normalizedXCoordinate:Float = (-1.0 + 2.0 * (Float)(xCoordinate / 4) / Float(inputSize.width)) * xAspectMultiplier;
                let normalizedYCoordinate:Float = (-1.0 + 2.0 * (Float)(yCoordinate) / Float(inputSize.height)) * yAspectMultiplier;

                // this might not be the most performant..
                minY = min(minY, normalizedYCoordinate);
                maxY = max(maxY, normalizedYCoordinate);
                minX = min(minX, normalizedXCoordinate);
                maxX = max(maxX, normalizedXCoordinate);
                //            NSLog(@"Parallel line coordinates: (%f, %f) - (%f, %f) - (%f, %f)", -1.0, -normalizedYCoordinate, 0.0, normalizedXCoordinate, 1.0, normalizedYCoordinate);
                // T space coordinates, (-d, -y) to (0, x)
                // Note - I really dont know if its better to just use signed ints.  Swift wont allow a UInt as an array index but
                // signed ints seem silly.  If this is a no-op, then fine.  But if casting like this hurts performance can look into
                // better solutions.

                // T space coordinates, (-d, -y) to (0, x)
                lineCoordinates[lineStorageIndex] = -1.0; lineStorageIndex += 1
                lineCoordinates[lineStorageIndex] = -normalizedYCoordinate; lineStorageIndex += 1
                lineCoordinates[lineStorageIndex] = 0.0; lineStorageIndex += 1
                lineCoordinates[lineStorageIndex] = normalizedXCoordinate; lineStorageIndex += 1

                // S space coordinates, (0, x) to (d, y)
                lineCoordinates[lineStorageIndex] = 0.0; lineStorageIndex += 1
                lineCoordinates[lineStorageIndex] = normalizedXCoordinate; lineStorageIndex += 1
                lineCoordinates[lineStorageIndex] = 1.0; lineStorageIndex += 1
                lineCoordinates[lineStorageIndex] = normalizedYCoordinate; lineStorageIndex += 1

                linePairsToRender += 1

                linePairsToRender = min(linePairsToRender, maxLinePairsToRender)
                lineStorageIndex = min(lineStorageIndex, maxLineStorageIndex)
            }
            currentByte += 8
        }
        //    NSLog(@"Line pairs to render: %d out of max: %d", linePairsToRender, maxLinePairsToRender);

        let currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
        print("Line generation processing time : \(1000.0 * currentFrameTime) ms for \(linePairsToRender) lines");
        renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:inputSize, stencil:mask != nil)
        releaseIncomingFramebuffers()
        renderFramebuffer.activateFramebufferForRendering()
//        clearFramebufferWithColor(Color.Black)

        // do we need this:
//        [self setUniformsForProgramAtIndex:0];
//        renderFramebuffer.lock() // may be unnecessary - what is teh GPUImage2 version of usingNextFrameForImageCapture
        shader.use()

        //
        // can we get rid of this from clearFrameBufferWithColor
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GLenum(GL_COLOR_BUFFER_BIT));
        //
        let supportsFrameBufferReads = sharedImageProcessingContext.deviceSupportsFramebufferReads()
        if (!supportsFrameBufferReads) {
            glBlendEquation(GLenum(GL_FUNC_ADD))
            glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE))
            glEnable(GLenum(GL_BLEND))
        }
        else
        {
        }

        glLineWidth(1);
        guard let filterPositionAttr = shader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }

        glVertexAttribPointer(filterPositionAttr, 2, GLenum(GL_FLOAT), 0, 0, lineCoordinates);
        glDrawArrays(GLenum(GL_LINES), 0, (Int32(linePairsToRender) * 4));

        if (!supportsFrameBufferReads)
        {
            glDisable(GLenum(GL_BLEND))
        }

//        [firstInputFramebuffer unlock];
//        if (usingNextFrameForImageCapture)
//        {
//            dispatch_semaphore_signal(imageCaptureSemaphore);
//        }

    }
}
