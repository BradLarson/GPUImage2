varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
}