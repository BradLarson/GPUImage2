attribute vec4 position;

varying vec3 colorFactor;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    float luminance = dot(position.xyz, W);

    colorFactor = vec3(1.0, 1.0, 1.0);
    gl_Position = vec4(-1.0 + (luminance * 0.0078125), 0.0, 0.0, 1.0);
    gl_PointSize = 1.0;
}