varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform mat4 colorMatrix;
uniform float intensity;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 outputColor = textureColor * colorMatrix;
    
    gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
}