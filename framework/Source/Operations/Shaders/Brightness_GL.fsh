varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float brightness;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
}
