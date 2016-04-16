varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float opacity;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.rgb, textureColor.a * opacity);
}