import XCTest

public let TestVertexShader = "attribute vec4 position;\n attribute vec4 inputTextureCoordinate;\n \n varying vec2 textureCoordinate;\n \n void main()\n {\n     gl_Position = position;\n     textureCoordinate = inputTextureCoordinate.xy;\n }\n "
public let TestFragmentShader = "varying vec2 textureCoordinate;\n \n uniform sampler2D inputImageTexture;\n \n void main()\n {\n     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\n }\n "
public let TestBrokenVertexShader = "attribute vec4 position;\n attribute vec4 inputTextureCoordinate;\n \n varing vec2 textureCoordinate;\n \n void main()\n {\n     gl_Position = position;\n     textureCoordinate = inputTextureCoordinate.xy;\n }\n "
public let TestBrokenFragmentShader = "varying vec2 textureCoordinate;\n \n uniform sampler2D inputImageTexture;\n \n void ma)\n {\n     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\n }\n "
public let TestMismatchedFragmentShader = "varying vec2 textureCoordinateF;\n \n uniform sampler2D inputImageTexture;\n \n void main()\n {\n     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);\n }\n "


class ShaderProgram_Tests: XCTestCase {

    func testExample() {
        sharedImageProcessingContext.makeCurrentContext()
        
        do {
            let shaderProgram = try ShaderProgram(vertexShader:TestVertexShader, fragmentShader:TestFragmentShader)
            let temporaryPosition = shaderProgram.attributeIndex("position")
            XCTAssert(temporaryPosition != nil, "Could not find position attribute")
            XCTAssert(temporaryPosition == shaderProgram.attributeIndex("position"), "Could not retrieve the same position attribute")
            let temporaryInputTextureCoordinate = shaderProgram.attributeIndex("inputTextureCoordinate")
            XCTAssert(temporaryInputTextureCoordinate != nil, "Could not find inputTextureCoordinate attribute")
            XCTAssert(temporaryInputTextureCoordinate == shaderProgram.attributeIndex("inputTextureCoordinate"), "Could not retrieve the same inputTextureCoordinate attribute")
            XCTAssert(shaderProgram.attributeIndex("garbage") == nil, "Should not have found the garbage attribute")

            let temporaryInputTexture = shaderProgram.uniformIndex("inputImageTexture")
            XCTAssert(temporaryInputTexture != nil, "Could not find inputImageTexture uniform")
            XCTAssert(temporaryInputTexture == shaderProgram.uniformIndex("inputImageTexture"), "Could not retrieve the same inputImageTexture uniform")
            XCTAssert(shaderProgram.uniformIndex("garbage") == nil, "Should not have found the garbage uniform")
        } catch {
            XCTFail("Should not have thrown error during shader compilation: \(error)")
        }

        if ((try? ShaderProgram(vertexShader:TestBrokenVertexShader, fragmentShader:TestFragmentShader)) != nil) {
            XCTFail("Program should not have compiled correctly")
        }

        if ((try? ShaderProgram(vertexShader:TestVertexShader, fragmentShader:TestBrokenFragmentShader)) != nil) {
            XCTFail("Program should not have compiled correctly")
        }

        if ((try? ShaderProgram(vertexShader:TestVertexShader, fragmentShader:TestMismatchedFragmentShader)) != nil) {
            XCTFail("Program should not have compiled correctly")
        }
    }

}
