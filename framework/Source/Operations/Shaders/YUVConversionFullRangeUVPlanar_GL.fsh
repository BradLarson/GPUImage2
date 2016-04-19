varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;
varying vec2 textureCoordinate3;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;
uniform sampler2D inputImageTexture3;

uniform mat3 colorConversionMatrix;

void main()
{
    vec3 yuv;
    
    yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
    yuv.y = texture2D(inputImageTexture2, textureCoordinate).r - 0.5;
    yuv.z = texture2D(inputImageTexture3, textureCoordinate).r - 0.5;
    vec3 rgb = colorConversionMatrix * yuv;
    
    gl_FragColor = vec4(rgb, 1.0);
}
