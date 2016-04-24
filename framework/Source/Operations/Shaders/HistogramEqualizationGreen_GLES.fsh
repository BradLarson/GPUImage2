varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    lowp float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
    
    gl_FragColor = vec4(textureColor.r, greenCurveValue, textureColor.b, textureColor.a);
}