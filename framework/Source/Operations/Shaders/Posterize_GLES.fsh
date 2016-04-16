varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform highp float colorLevels;

void main()
{
    highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
}