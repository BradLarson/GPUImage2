precision highp float;

uniform sampler2D inputImageTexture;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepLeftTextureCoordinate;
varying vec2 twoStepsLeftTextureCoordinate;
varying vec2 threeStepsLeftTextureCoordinate;
varying vec2 fourStepsLeftTextureCoordinate;
varying vec2 oneStepRightTextureCoordinate;
varying vec2 twoStepsRightTextureCoordinate;
varying vec2 threeStepsRightTextureCoordinate;
varying vec2 fourStepsRightTextureCoordinate;

// sinc(x) * sinc(x/a) = (a * sin(pi * x) * sin(pi * x / a)) / (pi^2 * x^2)
// Assuming a Lanczos constant of 2.0, and scaling values to max out at x = +/- 1.5

void main()
{
    lowp vec4 fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate) * 0.38026;
    
    fragmentColor += texture2D(inputImageTexture, oneStepLeftTextureCoordinate) * 0.27667;
    fragmentColor += texture2D(inputImageTexture, oneStepRightTextureCoordinate) * 0.27667;
    
    fragmentColor += texture2D(inputImageTexture, twoStepsLeftTextureCoordinate) * 0.08074;
    fragmentColor += texture2D(inputImageTexture, twoStepsRightTextureCoordinate) * 0.08074;

    fragmentColor += texture2D(inputImageTexture, threeStepsLeftTextureCoordinate) * -0.02612;
    fragmentColor += texture2D(inputImageTexture, threeStepsRightTextureCoordinate) * -0.02612;

    fragmentColor += texture2D(inputImageTexture, fourStepsLeftTextureCoordinate) * -0.02143;
    fragmentColor += texture2D(inputImageTexture, fourStepsRightTextureCoordinate) * -0.02143;

    gl_FragColor = fragmentColor;
}