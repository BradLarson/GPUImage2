varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float saturation;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);
    
    gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
 
}
