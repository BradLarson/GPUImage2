varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    
    vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
    
    gl_FragColor = max(maxValue, oneStepNegativeIntensity);
}