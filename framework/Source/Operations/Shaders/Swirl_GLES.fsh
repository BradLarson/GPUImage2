varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform highp vec2 center;
uniform highp float radius;
uniform highp float angle;

void main()
{
    highp vec2 textureCoordinateToUse = textureCoordinate;
    highp float dist = distance(center, textureCoordinate);
    if (dist < radius)
    {
        textureCoordinateToUse -= center;
        highp float percent = (radius - dist) / radius;
        highp float theta = percent * percent * angle * 8.0;
        highp float s = sin(theta);
        highp float c = cos(theta);
        textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
        textureCoordinateToUse += center;
    }
   
    gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
    
}