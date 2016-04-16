varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float intensity;

void main()
{
    vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
    vec3 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    
    gl_FragColor = vec4(sharpImageColor.rgb * intensity + blurredImageColor * (1.0 - intensity), sharpImageColor.a);
}