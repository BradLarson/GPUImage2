varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float mixturePercent;

void main()
{
 vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
 
 gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * mixturePercent), textureColor.a);
}