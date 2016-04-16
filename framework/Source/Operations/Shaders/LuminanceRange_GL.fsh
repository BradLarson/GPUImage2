varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float rangeReduction;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    float luminanceRatio = ((0.5 - luminance) * rangeReduction);
    
    gl_FragColor = vec4((textureColor.rgb) + (luminanceRatio), textureColor.w);
}