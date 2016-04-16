attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform mat4 transformMatrix;
uniform mat4 orthographicMatrix;

varying vec2 textureCoordinate;

void main()
{
    gl_Position = transformMatrix * vec4(position.xyz, 1.0) * orthographicMatrix;
    textureCoordinate = inputTextureCoordinate.xy;
}