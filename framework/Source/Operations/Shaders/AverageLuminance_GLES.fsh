precision highp float;

uniform sampler2D inputImageTexture;

varying highp vec2 outputTextureCoordinate;

varying highp vec2 upperLeftInputTextureCoordinate;
varying highp vec2 upperRightInputTextureCoordinate;
varying highp vec2 lowerLeftInputTextureCoordinate;
varying highp vec2 lowerRightInputTextureCoordinate;

void main()
{
    highp float upperLeftLuminance = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
    highp float upperRightLuminance = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
    highp float lowerLeftLuminance = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
    highp float lowerRightLuminance = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
    
    highp float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
    gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
}