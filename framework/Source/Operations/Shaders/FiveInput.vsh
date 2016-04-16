attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;
attribute vec4 inputTextureCoordinate3;
attribute vec4 inputTextureCoordinate4;
attribute vec4 inputTextureCoordinate5;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;
varying vec2 textureCoordinate3;
varying vec2 textureCoordinate4;
varying vec2 textureCoordinate5;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    textureCoordinate2 = inputTextureCoordinate2.xy;
    textureCoordinate3 = inputTextureCoordinate3.xy;
    textureCoordinate4 = inputTextureCoordinate4.xy;
    textureCoordinate5 = inputTextureCoordinate5.xy;
}