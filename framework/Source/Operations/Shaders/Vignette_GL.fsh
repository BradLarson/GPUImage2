uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

uniform vec2 vignetteCenter;
uniform vec3 vignetteColor;
uniform float vignetteStart;
uniform float vignetteEnd;

void main()
{
    vec4 sourceImageColor = texture2D(inputImageTexture, textureCoordinate);
    float d = distance(textureCoordinate, vec2(vignetteCenter.x, vignetteCenter.y));
    float percent = smoothstep(vignetteStart, vignetteEnd, d);
    gl_FragColor = vec4(mix(sourceImageColor.rgb, vignetteColor, percent), sourceImageColor.a);
}