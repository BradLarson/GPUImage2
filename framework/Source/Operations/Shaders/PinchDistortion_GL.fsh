varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float aspectRatio;
uniform vec2 center;
uniform float radius;
uniform float scale;

void main()
{
    vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    float dist = distance(center, textureCoordinateToUse);
    textureCoordinateToUse = textureCoordinate;
    
    if (dist < radius)
    {
        textureCoordinateToUse -= center;
        float percent = 1.0 + ((0.5 - dist) / 0.5) * scale;
        textureCoordinateToUse = textureCoordinateToUse * percent;
        textureCoordinateToUse += center;
        
        gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
    }
    else
    {
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate );
    }
}