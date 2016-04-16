varying vec2 textureCoordinate;
varying float height;

uniform sampler2D inputImageTexture;
vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 0.0);

void main()
{
    vec3 colorChannels = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec4 heightTest = vec4(step(height, colorChannels), 1.0);
    gl_FragColor = mix(backgroundColor, heightTest, heightTest.r + heightTest.g + heightTest.b);
}