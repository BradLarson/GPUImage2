varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float fractionalWidthOfPixel;
uniform float aspectRatio;

void main()
{
    vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
    
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
    gl_FragColor = texture2D(inputImageTexture, samplePos );
}