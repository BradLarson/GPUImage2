const lowp float scalingFactor = 0.004;
// const lowp float scalingFactor = 0.1;

void main()
{
    mediump vec4 fragmentData = gl_LastFragData[0];

    fragmentData.r = fragmentData.r + scalingFactor;
    fragmentData.g = scalingFactor * floor(fragmentData.r) + fragmentData.g;
    fragmentData.b = scalingFactor * floor(fragmentData.g) + fragmentData.b;
    fragmentData.a = scalingFactor * floor(fragmentData.b) + fragmentData.a;

    fragmentData = fract(fragmentData);

    gl_FragColor = vec4(fragmentData.rgb, 1.0);
}
