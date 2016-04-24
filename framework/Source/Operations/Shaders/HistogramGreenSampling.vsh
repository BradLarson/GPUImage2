attribute vec4 position;

varying vec3 colorFactor;

void main()
{
    colorFactor = vec3(0.0, 1.0, 0.0);
    gl_Position = vec4(-1.0 + (position.y * 0.0078125), 0.0, 0.0, 1.0);
    gl_PointSize = 1.0;
}