uniform vec3 circleColor;
uniform vec3 backgroundColor;
uniform vec2 center;
uniform float radius;

varying vec2 currentPosition;

void main()
{
    float distanceFromCenter = distance(center, currentPosition);
    float checkForPresenceWithinCircle = step(distanceFromCenter, radius);

    gl_FragColor = vec4(mix(backgroundColor, circleColor, checkForPresenceWithinCircle), checkForPresenceWithinCircle);
}