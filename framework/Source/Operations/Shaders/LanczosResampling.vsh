attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepLeftTextureCoordinate;
varying vec2 twoStepsLeftTextureCoordinate;
varying vec2 threeStepsLeftTextureCoordinate;
varying vec2 fourStepsLeftTextureCoordinate;
varying vec2 oneStepRightTextureCoordinate;
varying vec2 twoStepsRightTextureCoordinate;
varying vec2 threeStepsRightTextureCoordinate;
varying vec2 fourStepsRightTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 firstOffset = vec2(texelWidth, texelHeight);
    vec2 secondOffset = vec2(2.0 * texelWidth, 2.0 * texelHeight);
    vec2 thirdOffset = vec2(3.0 * texelWidth, 3.0 * texelHeight);
    vec2 fourthOffset = vec2(4.0 * texelWidth, 4.0 * texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepLeftTextureCoordinate = inputTextureCoordinate - firstOffset;
    twoStepsLeftTextureCoordinate = inputTextureCoordinate - secondOffset;
    threeStepsLeftTextureCoordinate = inputTextureCoordinate - thirdOffset;
    fourStepsLeftTextureCoordinate = inputTextureCoordinate - fourthOffset;
    oneStepRightTextureCoordinate = inputTextureCoordinate + firstOffset;
    twoStepsRightTextureCoordinate = inputTextureCoordinate + secondOffset;
    threeStepsRightTextureCoordinate = inputTextureCoordinate + thirdOffset;
    fourStepsRightTextureCoordinate = inputTextureCoordinate + fourthOffset;
}