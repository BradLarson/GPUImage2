varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform mat3 colorConversionMatrix;

void main()
{
    vec3 yuv;
    
    yuv.x = texture2D(inputImageTexture, textureCoordinate).r - (16.0/255.0);
    yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
    vec3 rgb = colorConversionMatrix * yuv;
    
    gl_FragColor = vec4(rgb, 1.0);
}