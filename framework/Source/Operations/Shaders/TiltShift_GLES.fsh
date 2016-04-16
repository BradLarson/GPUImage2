varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2; 

uniform highp float topFocusLevel;
uniform highp float bottomFocusLevel;
uniform highp float focusFallOffRate;

void main()
{
    lowp vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    lowp float blurIntensity = 1.0 - smoothstep(topFocusLevel - focusFallOffRate, topFocusLevel, textureCoordinate2.y);
    blurIntensity += smoothstep(bottomFocusLevel, bottomFocusLevel + focusFallOffRate, textureCoordinate2.y);
    
    gl_FragColor = mix(sharpImageColor, blurredImageColor, blurIntensity);
}