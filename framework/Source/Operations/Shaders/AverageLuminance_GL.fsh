uniform sampler2D inputImageTexture;

varying vec2 outputTextureCoordinate;

varying vec2 upperLeftInputTextureCoordinate;
varying vec2 upperRightInputTextureCoordinate;
varying vec2 lowerLeftInputTextureCoordinate;
varying vec2 lowerRightInputTextureCoordinate;

void main()
{
    float upperLeftLuminance = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
    float upperRightLuminance = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
    float lowerLeftLuminance = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
    float lowerRightLuminance = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
    
    float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
    gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
}