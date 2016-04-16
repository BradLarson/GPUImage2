attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth; 
uniform float texelHeight; 

varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 offset = vec2(texelWidth, texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
    oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
}