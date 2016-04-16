varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float exposure;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.rgb * pow(2.0, exposure), textureColor.w);
}