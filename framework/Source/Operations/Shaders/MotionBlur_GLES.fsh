precision highp float;

uniform sampler2D inputImageTexture;

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
    lowp vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
    fragmentColor += texture2D(inputImageTexture, oneStepBackTextureCoordinate) * 0.15;
    fragmentColor += texture2D(inputImageTexture, twoStepsBackTextureCoordinate) *  0.12;
    fragmentColor += texture2D(inputImageTexture, threeStepsBackTextureCoordinate) * 0.09;
    fragmentColor += texture2D(inputImageTexture, fourStepsBackTextureCoordinate) * 0.05;
    fragmentColor += texture2D(inputImageTexture, oneStepForwardTextureCoordinate) * 0.15;
    fragmentColor += texture2D(inputImageTexture, twoStepsForwardTextureCoordinate) *  0.12;
    fragmentColor += texture2D(inputImageTexture, threeStepsForwardTextureCoordinate) * 0.09;
    fragmentColor += texture2D(inputImageTexture, fourStepsForwardTextureCoordinate) * 0.05;

    gl_FragColor = fragmentColor;
}