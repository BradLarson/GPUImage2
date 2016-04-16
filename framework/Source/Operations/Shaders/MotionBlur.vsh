attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform vec2 directionalTexelStep;

varying vec2 textureCoordinate;
varying vec2 oneStepBackTextureCoordinate;
varying vec2 twoStepsBackTextureCoordinate;
varying vec2 threeStepsBackTextureCoordinate;
varying vec2 fourStepsBackTextureCoordinate;
varying vec2 oneStepForwardTextureCoordinate;
varying vec2 twoStepsForwardTextureCoordinate;
varying vec2 threeStepsForwardTextureCoordinate;
varying vec2 fourStepsForwardTextureCoordinate;

void main()
{
    gl_Position = position;
    
    textureCoordinate = inputTextureCoordinate.xy;
    oneStepBackTextureCoordinate = inputTextureCoordinate.xy - directionalTexelStep;
    twoStepsBackTextureCoordinate = inputTextureCoordinate.xy - 2.0 * directionalTexelStep;
    threeStepsBackTextureCoordinate = inputTextureCoordinate.xy - 3.0 * directionalTexelStep;
    fourStepsBackTextureCoordinate = inputTextureCoordinate.xy - 4.0 * directionalTexelStep;
    oneStepForwardTextureCoordinate = inputTextureCoordinate.xy + directionalTexelStep;
    twoStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 2.0 * directionalTexelStep;
    threeStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 3.0 * directionalTexelStep;
    fourStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 4.0 * directionalTexelStep;
}