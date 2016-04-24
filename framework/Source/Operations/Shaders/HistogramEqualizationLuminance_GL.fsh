varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, W);
    float newLuminance = texture2D(inputImageTexture2, vec2(luminance, 0.0)).r;
    float deltaLuminance = newLuminance - luminance;
    
    float red   = clamp(textureColor.r + deltaLuminance, 0.0, 1.0);
    float green = clamp(textureColor.g + deltaLuminance, 0.0, 1.0);
    float blue  = clamp(textureColor.b + deltaLuminance, 0.0, 1.0);
    
    gl_FragColor = vec4(red, green, blue, textureColor.a);
}