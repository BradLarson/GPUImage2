varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D toneCurveTexture;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float redCurveValue = texture2D(toneCurveTexture, vec2(textureColor.r, 0.0)).r;
    float greenCurveValue = texture2D(toneCurveTexture, vec2(textureColor.g, 0.0)).g;
    float blueCurveValue = texture2D(toneCurveTexture, vec2(textureColor.b, 0.0)).b;
    
    gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
}
