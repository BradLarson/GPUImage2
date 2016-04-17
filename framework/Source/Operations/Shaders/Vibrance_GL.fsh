varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float vibrance;

void main() {
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    float average = (color.r + color.g + color.b) / 3.0;
    float mx = max(color.r, max(color.g, color.b));
    float amt = (mx - average) * (-vibrance * 3.0);
    color.rgb = mix(color.rgb, vec3(mx), amt);
    gl_FragColor = color;
}