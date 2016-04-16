varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform highp float threshold;

const highp vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    highp float luminance = dot(textureColor.rgb, W);
    highp float thresholdResult = step(threshold, luminance);
    
    gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);
}