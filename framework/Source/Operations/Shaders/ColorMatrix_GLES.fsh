varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform lowp mat4 colorMatrix;
uniform lowp float intensity;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp vec4 outputColor = textureColor * colorMatrix;
    
    gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
}