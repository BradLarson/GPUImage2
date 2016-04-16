#version 120

uniform vec3 crosshairColor;

varying vec2 centerLocation;
varying float pointSpacing;

void main()
{
    vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
    float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);
    
    gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
    //     gl_FragColor = vec4(distanceFromCenterInX, distanceFromCenterInY, 0.0, 1.0);
}
