varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float topFocusLevel;
uniform float bottomFocusLevel;
uniform float focusFallOffRate;

void main()
{
    vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    float blurIntensity = 1.0 - smoothstep(topFocusLevel - focusFallOffRate, topFocusLevel, textureCoordinate2.y);
    blurIntensity += smoothstep(bottomFocusLevel, bottomFocusLevel + focusFallOffRate, textureCoordinate2.y);
    
    gl_FragColor = mix(sharpImageColor, blurredImageColor, blurIntensity);
}