precision highp float;

uniform sampler2D inputImageTexture;

varying highp vec2 outputTextureCoordinate;

varying highp vec2 upperLeftInputTextureCoordinate;
varying highp vec2 upperRightInputTextureCoordinate;
varying highp vec2 lowerLeftInputTextureCoordinate;
varying highp vec2 lowerRightInputTextureCoordinate;

void main()
{
    highp vec4 upperLeftColor = texture2D(inputImageTexture, upperLeftInputTextureCoordinate);
    highp vec4 upperRightColor = texture2D(inputImageTexture, upperRightInputTextureCoordinate);
    highp vec4 lowerLeftColor = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate);
    highp vec4 lowerRightColor = texture2D(inputImageTexture, lowerRightInputTextureCoordinate);
    
    gl_FragColor = 0.25 * (upperLeftColor + upperRightColor + lowerLeftColor + lowerRightColor);
}