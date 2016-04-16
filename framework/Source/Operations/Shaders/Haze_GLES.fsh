varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform lowp float hazeDistance;
uniform highp float slope;

void main()
{
//todo reconsider precision modifiers
 highp vec4 color = vec4(1.0);//todo reimplement as a parameter
 
 highp float  d = textureCoordinate.y * slope  +  hazeDistance;
 
 highp vec4 c = texture2D(inputImageTexture, textureCoordinate) ; // consider using unpremultiply
 
 c = (c - d * color) / (1.0 -d);
 
 gl_FragColor = c; //consider using premultiply(c);
}