varying highp vec2 textureCoordinate;
varying highp float height;

uniform sampler2D inputImageTexture;
lowp vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 0.0);

void main()
{
    lowp vec3 colorChannels = texture2D(inputImageTexture, textureCoordinate).rgb;
    lowp vec4 heightTest = vec4(step(height, colorChannels), 1.0);
    gl_FragColor = mix(backgroundColor, heightTest, heightTest.r + heightTest.g + heightTest.b);
}