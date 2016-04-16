attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform float texelWidth; 
uniform float texelHeight; 
uniform float sharpness;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate; 
varying vec2 topTextureCoordinate;
varying vec2 bottomTextureCoordinate;

varying float centerMultiplier;
varying float edgeMultiplier;

void main()
{
    gl_Position = position;
    
    vec2 widthStep = vec2(texelWidth, 0.0);
    vec2 heightStep = vec2(0.0, texelHeight);
    
    textureCoordinate = inputTextureCoordinate.xy;
    leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
    rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
    topTextureCoordinate = inputTextureCoordinate.xy + heightStep;     
    bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;
    
    centerMultiplier = 1.0 + 4.0 * sharpness;
    edgeMultiplier = sharpness;
}