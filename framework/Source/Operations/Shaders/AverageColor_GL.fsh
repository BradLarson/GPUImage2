uniform sampler2D inputImageTexture;

varying vec2 outputTextureCoordinate;

varying vec2 upperLeftInputTextureCoordinate;
varying vec2 upperRightInputTextureCoordinate;
varying vec2 lowerLeftInputTextureCoordinate;
varying vec2 lowerRightInputTextureCoordinate;

void main()
{
    vec4 upperLeftColor = texture2D(inputImageTexture, upperLeftInputTextureCoordinate);
    vec4 upperRightColor = texture2D(inputImageTexture, upperRightInputTextureCoordinate);
    vec4 lowerLeftColor = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate);
    vec4 lowerRightColor = texture2D(inputImageTexture, lowerRightInputTextureCoordinate);
    
    gl_FragColor = 0.25 * (upperLeftColor + upperRightColor + lowerLeftColor + lowerRightColor);
}