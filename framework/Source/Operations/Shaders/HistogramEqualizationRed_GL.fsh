varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
    
    gl_FragColor = vec4(redCurveValue, textureColor.g, textureColor.b, textureColor.a);
}