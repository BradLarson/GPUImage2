attribute vec4 position;
attribute vec4 inputTextureCoordinate;

const int GAUSSIAN_SAMPLES = 9;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 textureCoordinate;
varying vec2 blurCoordinates[GAUSSIAN_SAMPLES];

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    
    // Calculate the positions for the blur
    int multiplier = 0;
    vec2 blurStep;
    vec2 singleStepOffset = vec2(texelWidth, texelHeight);
    
    for (int i = 0; i < GAUSSIAN_SAMPLES; i++)
    {
        multiplier = (i - ((GAUSSIAN_SAMPLES - 1) / 2));
        // Blur in x (horizontal)
        blurStep = float(multiplier) * singleStepOffset;
        blurCoordinates[i] = inputTextureCoordinate.xy + blurStep;
    }
}