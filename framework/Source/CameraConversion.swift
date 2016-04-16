// Note: the original name of YUVToRGBConversion.swift for this file chokes the compiler on Linux for some reason

// BT.601, which is the standard for SDTV.
let colorConversionMatrix601Default = Matrix3x3(rowMajorValues:[
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0
])

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
let colorConversionMatrix601FullRangeDefault = Matrix3x3(rowMajorValues:[
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
])

// BT.709, which is the standard for HDTV.
let colorConversionMatrix709Default = Matrix3x3(rowMajorValues:[
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
])

func convertYUVToRGB(shader shader:ShaderProgram, luminanceFramebuffer:Framebuffer, chrominanceFramebuffer:Framebuffer, resultFramebuffer:Framebuffer, colorConversionMatrix:Matrix3x3) {
    let textureProperties = [luminanceFramebuffer.texturePropertiesForTargetOrientation(resultFramebuffer.orientation), chrominanceFramebuffer.texturePropertiesForTargetOrientation(resultFramebuffer.orientation)]
    resultFramebuffer.activateFramebufferForRendering()
    clearFramebufferWithColor(Color.Black)
    var uniformSettings = ShaderUniformSettings()
    uniformSettings["colorConversionMatrix"] = colorConversionMatrix
    renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:textureProperties)
    luminanceFramebuffer.unlock()
    chrominanceFramebuffer.unlock()
}