uniform lowp vec3 crosshairColor;

varying highp vec2 centerLocation;
varying highp float pointSpacing;

void main()
{
    lowp vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
    lowp float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);

    gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
//     gl_FragColor = vec4(distanceFromCenterInX, distanceFromCenterInY, 0.0, 1.0);
}