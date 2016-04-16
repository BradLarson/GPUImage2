varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform highp float intensity;

void main()
{
    lowp vec3 currentImageColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    lowp vec3 lowPassImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    
    mediump float colorDistance = distance(currentImageColor, lowPassImageColor); // * 0.57735
    lowp float movementThreshold = step(0.2, colorDistance);
    
    gl_FragColor = movementThreshold * vec4(textureCoordinate2.x, textureCoordinate2.y, 1.0, 1.0);
}