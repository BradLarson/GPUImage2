varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float shadowTintIntensity;
uniform float highlightTintIntensity;
uniform vec3 shadowTintColor;
uniform vec3 highlightTintColor;

const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
   vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   float luminance = dot(textureColor.rgb, luminanceWeighting);
    
   vec4 shadowResult = mix(textureColor, max(textureColor, vec4( mix(shadowTintColor, textureColor.rgb, luminance), textureColor.a)), shadowTintIntensity);
   vec4 highlightResult = mix(textureColor, min(shadowResult, vec4( mix(shadowResult.rgb, highlightTintColor.rgb, luminance), textureColor.a)), highlightTintIntensity);
    
   gl_FragColor = vec4( mix(shadowResult.rgb, highlightResult.rgb, luminance), textureColor.a);
}