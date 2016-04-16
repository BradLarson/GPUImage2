varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2; 

uniform highp float intensity;

void main()
{
    lowp vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec3 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    
    gl_FragColor = vec4(sharpImageColor.rgb * intensity + blurredImageColor * (1.0 - intensity), sharpImageColor.a);
}
