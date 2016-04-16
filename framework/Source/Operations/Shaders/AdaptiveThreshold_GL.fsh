varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    float blurredInput = texture2D(inputImageTexture, textureCoordinate).r;
    float localLuminance = texture2D(inputImageTexture2, textureCoordinate2).r;
    float thresholdResult = step(blurredInput - 0.05, localLuminance);
    
    gl_FragColor = vec4(vec3(thresholdResult), 1.0);
}