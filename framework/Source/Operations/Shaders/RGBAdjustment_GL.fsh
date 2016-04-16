varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float redAdjustment;
uniform float greenAdjustment;
uniform float blueAdjustment;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.r * redAdjustment, textureColor.g * greenAdjustment, textureColor.b * blueAdjustment, textureColor.a);
}