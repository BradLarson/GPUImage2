varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform highp float aspectRatio;
uniform highp vec2 center;
uniform highp float radius;
uniform highp float scale;

void main()
{
    highp vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    highp float dist = distance(center, textureCoordinateToUse);
    textureCoordinateToUse = textureCoordinate;
    
    if (dist < radius)
    {
        textureCoordinateToUse -= center;
        highp float percent = 1.0 + ((0.5 - dist) / 0.5) * scale;
        textureCoordinateToUse = textureCoordinateToUse * percent;
        textureCoordinateToUse += center;
        
        gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
    }
    else
    {
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate );
    }
}