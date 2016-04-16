uniform lowp vec3 circleColor;
uniform lowp vec3 backgroundColor;
uniform highp vec2 center;
uniform highp float radius;

varying highp vec2 currentPosition;

void main()
{
    highp float distanceFromCenter = distance(center, currentPosition);
    highp float checkForPresenceWithinCircle = step(distanceFromCenter, radius);

    gl_FragColor = vec4(mix(backgroundColor, circleColor, checkForPresenceWithinCircle), checkForPresenceWithinCircle);
}