attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;
varying float height;

void main()
{
    gl_Position = position;
    textureCoordinate = vec2(inputTextureCoordinate.x, 0.5);
    height = 1.0 - inputTextureCoordinate.y;
}