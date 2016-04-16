varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float hazeDistance;
uniform float slope;

void main()
{
    //todo reconsider precision modifiers
 vec4 color = vec4(1.0);//todo reimplement as a parameter
 
 float  d = textureCoordinate.y * slope  +  hazeDistance;
 
 vec4 c = texture2D(inputImageTexture, textureCoordinate) ; // consider using unpremultiply
 
 c = (c - d * color) / (1.0 -d);
 
 gl_FragColor = c; //consider using premultiply(c);
}