varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float colorLevels;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
}