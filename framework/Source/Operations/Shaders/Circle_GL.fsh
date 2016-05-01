uniform vec4 circleColor;
uniform vec4 backgroundColor;
uniform vec2 center;
uniform float radius;

varying vec2 currentPosition;

void main()
{
    float distanceFromCenter = distance(center, currentPosition);
    float checkForPresenceWithinCircle = step(distanceFromCenter, radius);

    gl_FragColor = mix(backgroundColor, circleColor, checkForPresenceWithinCircle);
}