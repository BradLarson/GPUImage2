precision lowp float;

varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float shadowTintIntensity;
uniform lowp float highlightTintIntensity;
uniform highp vec3 shadowTintColor;
uniform highp vec3 highlightTintColor;

const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   highp float luminance = dot(textureColor.rgb, luminanceWeighting);
    
   highp vec4 shadowResult = mix(textureColor, max(textureColor, vec4( mix(shadowTintColor, textureColor.rgb, luminance), textureColor.a)), shadowTintIntensity);
   highp vec4 highlightResult = mix(textureColor, min(shadowResult, vec4( mix(shadowResult.rgb, highlightTintColor, luminance), textureColor.a)), highlightTintIntensity);

   gl_FragColor = vec4( mix(shadowResult.rgb, highlightResult.rgb, luminance), textureColor.a);
}