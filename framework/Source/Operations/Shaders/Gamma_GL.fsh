varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float gamma;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(pow(textureColor.rgb, vec3(gamma)), textureColor.w);
}