varying highp vec2 textureCoordinate;
varying highp vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2; 

void main()
{
    highp float blurredInput = texture2D(inputImageTexture, textureCoordinate).r;
    highp float localLuminance = texture2D(inputImageTexture2, textureCoordinate2).r;
    highp float thresholdResult = step(blurredInput - 0.05, localLuminance);
    
    gl_FragColor = vec4(vec3(thresholdResult), 1.0);
}