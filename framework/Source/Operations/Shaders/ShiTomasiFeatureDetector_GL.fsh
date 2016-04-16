varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float sensitivity;

void main()
{
    vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
    
    float derivativeDifference = derivativeElements.x - derivativeElements.y;
    float zElement = (derivativeElements.z * 2.0) - 1.0;
    
    // R = Ix^2 + Iy^2 - sqrt( (Ix^2 - Iy^2)^2 + 4 * Ixy * Ixy)
    float cornerness = derivativeElements.x + derivativeElements.y - sqrt(derivativeDifference * derivativeDifference + 4.0 * zElement * zElement);
    
    gl_FragColor = vec4(vec3(cornerness * sensitivity), 1.0);
}