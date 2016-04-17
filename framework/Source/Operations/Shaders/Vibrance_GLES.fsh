varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float vibrance;

void main() {
    lowp vec4 color = texture2D(inputImageTexture, textureCoordinate);
    lowp float average = (color.r + color.g + color.b) / 3.0;
    lowp float mx = max(color.r, max(color.g, color.b));
    lowp float amt = (mx - average) * (-vibrance * 3.0);
    color.rgb = mix(color.rgb, vec3(mx), amt);
    gl_FragColor = color;
}