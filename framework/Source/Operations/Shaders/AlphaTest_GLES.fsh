varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    lowp vec4 color = texture2D(inputImageTexture, textureCoordinate);
    if (color.a < 0.5) 
    {
        discard;
    } 
    else
    {
        gl_FragColor = color;
    }
}