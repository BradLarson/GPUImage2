const lowp float scalingFactor = 1.0 / 256.0;

varying lowp vec3 colorFactor;

void main()
{
    gl_FragColor = vec4(colorFactor * scalingFactor , 1.0);
}