attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 textureCoordinate;
varying vec2 pointATextureCoordinate;
varying vec2 pointBTextureCoordinate;
varying vec2 pointCTextureCoordinate;
varying vec2 pointDTextureCoordinate;
varying vec2 pointETextureCoordinate;
varying vec2 pointFTextureCoordinate;
varying vec2 pointGTextureCoordinate;
varying vec2 pointHTextureCoordinate;

void main()
{
    gl_Position = position;
    
    float tripleTexelWidth = 3.0 * texelWidth;
    float tripleTexelHeight = 3.0 * texelHeight;
    
    textureCoordinate = inputTextureCoordinate.xy;
    
    pointATextureCoordinate = vec2(inputTextureCoordinate2.x + tripleTexelWidth, textureCoordinate.y + texelHeight);
    pointBTextureCoordinate = vec2(inputTextureCoordinate2.x + texelWidth, textureCoordinate.y + tripleTexelHeight);
    pointCTextureCoordinate = vec2(inputTextureCoordinate2.x - texelWidth, textureCoordinate.y + tripleTexelHeight);
    pointDTextureCoordinate = vec2(inputTextureCoordinate2.x - tripleTexelWidth, textureCoordinate.y + texelHeight);
    pointETextureCoordinate = vec2(inputTextureCoordinate2.x - tripleTexelWidth, textureCoordinate.y - texelHeight);
    pointFTextureCoordinate = vec2(inputTextureCoordinate2.x - texelWidth, textureCoordinate.y - tripleTexelHeight);
    pointGTextureCoordinate = vec2(inputTextureCoordinate2.x + texelWidth, textureCoordinate.y - tripleTexelHeight);
    pointHTextureCoordinate = vec2(inputTextureCoordinate2.x + tripleTexelWidth, textureCoordinate.y - texelHeight);
}