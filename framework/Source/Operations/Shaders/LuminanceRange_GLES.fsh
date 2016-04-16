varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float rangeReduction;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    mediump float luminance = dot(textureColor.rgb, luminanceWeighting);
    mediump float luminanceRatio = ((0.5 - luminance) * rangeReduction);
    
    gl_FragColor = vec4((textureColor.rgb) + (luminanceRatio), textureColor.w);
}