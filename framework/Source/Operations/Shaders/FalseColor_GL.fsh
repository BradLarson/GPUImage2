varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float intensity;
uniform vec3 firstColor;
uniform vec3 secondColor;

const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    
    gl_FragColor = vec4( mix(firstColor.rgb, secondColor.rgb, luminance), textureColor.a);
}