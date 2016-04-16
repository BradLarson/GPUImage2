attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 upperLeftInputTextureCoordinate;
varying vec2 upperRightInputTextureCoordinate;
varying vec2 lowerLeftInputTextureCoordinate;
varying vec2 lowerRightInputTextureCoordinate;

void main()
{
    gl_Position = position;
    
    upperLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, -texelHeight);
    upperRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, -texelHeight);
    lowerLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, texelHeight);
    lowerRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, texelHeight);
}