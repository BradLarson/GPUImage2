varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform highp vec2 center;
uniform highp vec2 pixelSize;


void main()
{
    highp vec2 normCoord = 2.0 * textureCoordinate - 1.0;
    highp vec2 normCenter = 2.0 * center - 1.0;
    
    normCoord -= normCenter;
    
    highp float r = length(normCoord); // to polar coords 
    highp float phi = atan(normCoord.y, normCoord.x); // to polar coords 
    
    r = r - mod(r, pixelSize.x) + 0.03;
    phi = phi - mod(phi, pixelSize.y);
          
    normCoord.x = r * cos(phi);
    normCoord.y = r * sin(phi);
     
    normCoord += normCenter;
    
    mediump vec2 textureCoordinateToUse = normCoord / 2.0 + 0.5;
    
    gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
    
}