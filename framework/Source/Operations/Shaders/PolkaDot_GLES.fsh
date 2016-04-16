varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform highp float fractionalWidthOfPixel;
uniform highp float aspectRatio;
uniform highp float dotScaling;

void main()
{
    highp vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
    
    highp vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
    highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    highp vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    highp float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
    lowp float checkForPresenceWithinDot = step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);

    lowp vec4 inputColor = texture2D(inputImageTexture, samplePos);
    
    gl_FragColor = vec4(inputColor.rgb * checkForPresenceWithinDot, inputColor.a);
}