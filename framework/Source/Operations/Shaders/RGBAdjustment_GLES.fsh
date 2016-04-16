varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform highp float redAdjustment;
uniform highp float greenAdjustment;
uniform highp float blueAdjustment;

void main()
{
    highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.r * redAdjustment, textureColor.g * greenAdjustment, textureColor.b * blueAdjustment, textureColor.a);
}
