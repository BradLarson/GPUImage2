varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, W);
    
    gl_FragColor = vec4(vec3(luminance), textureColor.a);
}