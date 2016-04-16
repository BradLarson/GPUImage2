varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float fractionalWidthOfPixel;
uniform float aspectRatio;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
    
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
    vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
    
    vec3 sampledColor = texture2D(inputImageTexture, samplePos ).rgb;
    float dotScaling = 1.0 - dot(sampledColor, W);
    
    float checkForPresenceWithinDot = 1.0 - step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);
    
    gl_FragColor = vec4(vec3(checkForPresenceWithinDot), 1.0);
}