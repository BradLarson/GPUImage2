varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 center;
uniform float radius;
uniform float angle;

void main()
{
    vec2 textureCoordinateToUse = textureCoordinate;
    float dist = distance(center, textureCoordinate);
    if (dist < radius)
    {
        textureCoordinateToUse -= center;
        float percent = (radius - dist) / radius;
        float theta = percent * percent * angle * 8.0;
        float s = sin(theta);
        float c = cos(theta);
        textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
        textureCoordinateToUse += center;
    }
    
    gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
}