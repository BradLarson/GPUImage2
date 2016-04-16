precision highp float;

uniform sampler2D inputImageTexture;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

void main()
{
    mediump vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
    mediump vec3 bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb;
    mediump vec3 bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb;
    mediump vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
    mediump vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
    mediump vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
    mediump vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
    mediump vec3 topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate).rgb;
    mediump vec3 topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate).rgb;
    
    mediump vec3 resultColor = topLeftColor * 0.5 + topColor * 1.0 + topRightColor * 0.5;
    resultColor += leftColor * 1.0 + centerColor.rgb * (-6.0) + rightColor * 1.0;
    resultColor += bottomLeftColor * 0.5 + bottomColor * 1.0 + bottomRightColor * 0.5;
    
    // Normalize the results to allow for negative gradients in the 0.0-1.0 colorspace
    resultColor = resultColor + 0.5;
    
    gl_FragColor = vec4(resultColor, centerColor.a);
}