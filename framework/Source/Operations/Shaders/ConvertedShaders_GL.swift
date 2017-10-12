public let AdaptiveThresholdFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    float blurredInput = texture2D(inputImageTexture, textureCoordinate).r;
    float localLuminance = texture2D(inputImageTexture2, textureCoordinate2).r;
    float thresholdResult = step(blurredInput - 0.05, localLuminance);
    
    gl_FragColor = vec4(vec3(thresholdResult), 1.0);
}
"""
public let AddBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
 
    float r;
    if (overlay.r * base.a + base.r * overlay.a >= overlay.a * base.a) {
        r = overlay.a * base.a + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        r = overlay.r + base.r;
    }
    
    float g;
    if (overlay.g * base.a + base.g * overlay.a >= overlay.a * base.a) {
        g = overlay.a * base.a + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        g = overlay.g + base.g;
    }
    
    float b;
    if (overlay.b * base.a + base.b * overlay.a >= overlay.a * base.a) {
        b = overlay.a * base.a + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        b = overlay.b + base.b;
    }
    
    float a = overlay.a + base.a - overlay.a * base.a;
    
    gl_FragColor = vec4(r, g, b, a);
}
"""
public let AlphaBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float mixturePercent;

void main()
{
 vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
 
 gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * mixturePercent), textureColor.a);
}
"""
public let AlphaTestFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    if (color.a < 0.5) 
    {
        discard;
    } 
    else
    {
        gl_FragColor = color;
    }
}
"""
public let AverageColorVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 upperLeftInputTextureCoordinate;
varying vec2 upperRightInputTextureCoordinate;
varying vec2 lowerLeftInputTextureCoordinate;
varying vec2 lowerRightInputTextureCoordinate;

void main()
{
    gl_Position = position;
    
    upperLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, -texelHeight);
    upperRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, -texelHeight);
    lowerLeftInputTextureCoordinate = inputTextureCoordinate.xy + vec2(-texelWidth, texelHeight);
    lowerRightInputTextureCoordinate = inputTextureCoordinate.xy + vec2(texelWidth, texelHeight);
}
"""
public let AverageColorFragmentShader = """
uniform sampler2D inputImageTexture;

varying vec2 outputTextureCoordinate;

varying vec2 upperLeftInputTextureCoordinate;
varying vec2 upperRightInputTextureCoordinate;
varying vec2 lowerLeftInputTextureCoordinate;
varying vec2 lowerRightInputTextureCoordinate;

void main()
{
    vec4 upperLeftColor = texture2D(inputImageTexture, upperLeftInputTextureCoordinate);
    vec4 upperRightColor = texture2D(inputImageTexture, upperRightInputTextureCoordinate);
    vec4 lowerLeftColor = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate);
    vec4 lowerRightColor = texture2D(inputImageTexture, lowerRightInputTextureCoordinate);
    
    gl_FragColor = 0.25 * (upperLeftColor + upperRightColor + lowerLeftColor + lowerRightColor);
}
"""
public let AverageLuminanceFragmentShader = """
uniform sampler2D inputImageTexture;

varying vec2 outputTextureCoordinate;

varying vec2 upperLeftInputTextureCoordinate;
varying vec2 upperRightInputTextureCoordinate;
varying vec2 lowerLeftInputTextureCoordinate;
varying vec2 lowerRightInputTextureCoordinate;

void main()
{
    float upperLeftLuminance = texture2D(inputImageTexture, upperLeftInputTextureCoordinate).r;
    float upperRightLuminance = texture2D(inputImageTexture, upperRightInputTextureCoordinate).r;
    float lowerLeftLuminance = texture2D(inputImageTexture, lowerLeftInputTextureCoordinate).r;
    float lowerRightLuminance = texture2D(inputImageTexture, lowerRightInputTextureCoordinate).r;
    
    float luminosity = 0.25 * (upperLeftLuminance + upperRightLuminance + lowerLeftLuminance + lowerRightLuminance);
    gl_FragColor = vec4(luminosity, luminosity, luminosity, 1.0);
}
"""
public let BilateralBlurVertexShader = """
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
"""
public let BilateralBlurFragmentShader = """
uniform sampler2D inputImageTexture;

const int GAUSSIAN_SAMPLES = 9;

varying vec2 textureCoordinate;
varying vec2 blurCoordinates[GAUSSIAN_SAMPLES];

uniform float distanceNormalizationFactor;

void main()
{
    vec4 centralColor;
    float gaussianWeightTotal;
    vec4 sum;
    vec4 sampleColor;
    float distanceFromCentralColor;
    float gaussianWeight;
    
    centralColor = texture2D(inputImageTexture, blurCoordinates[4]);
    gaussianWeightTotal = 0.18;
    sum = centralColor * 0.18;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[0]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[1]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[2]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[3]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[5]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.15 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[6]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.12 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[7]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.09 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    sampleColor = texture2D(inputImageTexture, blurCoordinates[8]);
    distanceFromCentralColor = min(distance(centralColor, sampleColor) * distanceNormalizationFactor, 1.0);
    gaussianWeight = 0.05 * (1.0 - distanceFromCentralColor);
    gaussianWeightTotal += gaussianWeight;
    sum += sampleColor * gaussianWeight;
    
    gl_FragColor = sum / gaussianWeightTotal;
}
"""
public let BrightnessFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float brightness;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
}

"""
public let BulgeDistortionFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float aspectRatio;
uniform vec2 center;
uniform float radius;
uniform float scale;

void main()
{
   vec2 textureCoordinateToUse = vec2(textureCoordinate.x, ((textureCoordinate.y - center.y) * aspectRatio) + center.y);
   float dist = distance(center, textureCoordinateToUse);
   textureCoordinateToUse = textureCoordinate;
   
   if (dist < radius)
   {
       textureCoordinateToUse -= center;
       float percent = 1.0 - ((radius - dist) / radius) * scale;
       percent = percent * percent;
       
       textureCoordinateToUse = textureCoordinateToUse * percent;
       textureCoordinateToUse += center;
   }
   
   gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
}
"""
public let CGAColorspaceFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec2 sampleDivisor = vec2(1.0 / 200.0, 1.0 / 320.0);
    //highp vec4 colorDivisor = vec4(colorDepth);
    
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor);
    vec4 color = texture2D(inputImageTexture, samplePos );
    
    //gl_FragColor = texture2D(inputImageTexture, samplePos );
    vec4 colorCyan = vec4(85.0 / 255.0, 1.0, 1.0, 1.0);
    vec4 colorMagenta = vec4(1.0, 85.0 / 255.0, 1.0, 1.0);
    vec4 colorWhite = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 colorBlack = vec4(0.0, 0.0, 0.0, 1.0);
    
    vec4 endColor;
    float blackDistance = distance(color, colorBlack);
    float whiteDistance = distance(color, colorWhite);
    float magentaDistance = distance(color, colorMagenta);
    float cyanDistance = distance(color, colorCyan);
    
    vec4 finalColor;
    
    float colorDistance = min(magentaDistance, cyanDistance);
    colorDistance = min(colorDistance, whiteDistance);
    colorDistance = min(colorDistance, blackDistance);
    
    if (colorDistance == blackDistance) {
        finalColor = colorBlack;
    } else if (colorDistance == whiteDistance) {
        finalColor = colorWhite;
    } else if (colorDistance == cyanDistance) {
        finalColor = colorCyan;
    } else {
        finalColor = colorMagenta;
    }
    
    gl_FragColor = finalColor;
}

"""
public let ChromaKeyBlendFragmentShader = """
// Shader code based on Apple's CIChromaKeyFilter example: https://developer.apple.com/library/mac/#samplecode/CIChromaKeyFilter/Introduction/Intro.html

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform float thresholdSensitivity;
uniform float smoothing;
uniform vec3 colorToReplace;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    
    float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
    float maskCr = 0.7132 * (colorToReplace.r - maskY);
    float maskCb = 0.5647 * (colorToReplace.b - maskY);
    
    float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
    float Cr = 0.7132 * (textureColor.r - Y);
    float Cb = 0.5647 * (textureColor.b - Y);
    
    //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
    float blendValue = 1.0 - smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
    gl_FragColor = mix(textureColor, textureColor2, blendValue);
}
"""
public let ChromaKeyFragmentShader = """
// Shader code based on Apple's CIChromaKeyFilter example: https://developer.apple.com/library/mac/#samplecode/CIChromaKeyFilter/Introduction/Intro.html

varying vec2 textureCoordinate;

uniform float thresholdSensitivity;
uniform float smoothing;
uniform vec3 colorToReplace;
uniform sampler2D inputImageTexture;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    float maskY = 0.2989 * colorToReplace.r + 0.5866 * colorToReplace.g + 0.1145 * colorToReplace.b;
    float maskCr = 0.7132 * (colorToReplace.r - maskY);
    float maskCb = 0.5647 * (colorToReplace.b - maskY);
    
    float Y = 0.2989 * textureColor.r + 0.5866 * textureColor.g + 0.1145 * textureColor.b;
    float Cr = 0.7132 * (textureColor.r - Y);
    float Cb = 0.5647 * (textureColor.b - Y);
    
    //     float blendValue = 1.0 - smoothstep(thresholdSensitivity - smoothing, thresholdSensitivity , abs(Cr - maskCr) + abs(Cb - maskCb));
    float blendValue = smoothstep(thresholdSensitivity, thresholdSensitivity + smoothing, distance(vec2(Cr, Cb), vec2(maskCr, maskCb)));
    gl_FragColor = vec4(textureColor.rgb, textureColor.a * blendValue);
}
"""
public let CircleVertexShader = """
attribute vec4 position;
varying vec2 currentPosition;
uniform float aspectRatio;

void main()
{
    currentPosition = vec2(position.x, position.y * aspectRatio);
    gl_Position = position;
}
"""
public let CircleFragmentShader = """
uniform vec4 circleColor;
uniform vec4 backgroundColor;
uniform vec2 center;
uniform float radius;

varying vec2 currentPosition;

void main()
{
    float distanceFromCenter = distance(center, currentPosition);
    float checkForPresenceWithinCircle = step(distanceFromCenter, radius);

    gl_FragColor = mix(backgroundColor, circleColor, checkForPresenceWithinCircle);
}
"""
public let ColorBlendFragmentShader = """
// Color blend mode based upon pseudo code from the PDF specification.

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

float lum(vec3 c) {
    return dot(c, vec3(0.3, 0.59, 0.11));
}

vec3 clipcolor(vec3 c) {
    float l = lum(c);
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    
    if (n < 0.0) {
        c.r = l + ((c.r - l) * l) / (l - n);
        c.g = l + ((c.g - l) * l) / (l - n);
        c.b = l + ((c.b - l) * l) / (l - n);
    }
    if (x > 1.0) {
        c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
        c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
        c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
    }
    
    return c;
}

vec3 setlum(vec3 c, float l) {
    float d = l - lum(c);
    c = c + vec3(d);
    return clipcolor(c);
}

void main()
{
 vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(overlayColor.rgb, lum(baseColor.rgb)) * overlayColor.a, baseColor.a);
}
"""
public let ColorBurnBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    vec4 whiteColor = vec4(1.0);
    gl_FragColor = whiteColor - (whiteColor - textureColor) / textureColor2;
}
"""
public let ColorDodgeBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
    
    vec3 baseOverlayAlphaProduct = vec3(overlay.a * base.a);
    vec3 rightHandProduct = overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a);
    
    vec3 firstBlendColor = baseOverlayAlphaProduct + rightHandProduct;
    vec3 overlayRGB = clamp((overlay.rgb / clamp(overlay.a, 0.01, 1.0)) * step(0.0, overlay.a), 0.0, 0.99);
    
    vec3 secondBlendColor = (base.rgb * overlay.a) / (1.0 - overlayRGB) + rightHandProduct;
    
    vec3 colorChoice = step((overlay.rgb * base.a + base.rgb * overlay.a), baseOverlayAlphaProduct);
    
    gl_FragColor = vec4(mix(firstBlendColor, secondBlendColor, colorChoice), 1.0);
}
"""
public let ColorInvertFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4((1.0 - textureColor.rgb), textureColor.w);
}
"""
public let ColorLocalBinaryPatternFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec3 centerColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec3 bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb;
    vec3 topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate).rgb;
    vec3 topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate).rgb;
    vec3 bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb;
    vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
    vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
    vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
    vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
    
    float redByteTally = 1.0 / 255.0 * step(centerColor.r, topRightColor.r);
    redByteTally += 2.0 / 255.0 * step(centerColor.r, topColor.r);
    redByteTally += 4.0 / 255.0 * step(centerColor.r, topLeftColor.r);
    redByteTally += 8.0 / 255.0 * step(centerColor.r, leftColor.r);
    redByteTally += 16.0 / 255.0 * step(centerColor.r, bottomLeftColor.r);
    redByteTally += 32.0 / 255.0 * step(centerColor.r, bottomColor.r);
    redByteTally += 64.0 / 255.0 * step(centerColor.r, bottomRightColor.r);
    redByteTally += 128.0 / 255.0 * step(centerColor.r, rightColor.r);
    
    float blueByteTally = 1.0 / 255.0 * step(centerColor.b, topRightColor.b);
    blueByteTally += 2.0 / 255.0 * step(centerColor.b, topColor.b);
    blueByteTally += 4.0 / 255.0 * step(centerColor.b, topLeftColor.b);
    blueByteTally += 8.0 / 255.0 * step(centerColor.b, leftColor.b);
    blueByteTally += 16.0 / 255.0 * step(centerColor.b, bottomLeftColor.b);
    blueByteTally += 32.0 / 255.0 * step(centerColor.b, bottomColor.b);
    blueByteTally += 64.0 / 255.0 * step(centerColor.b, bottomRightColor.b);
    blueByteTally += 128.0 / 255.0 * step(centerColor.b, rightColor.b);
    
    float greenByteTally = 1.0 / 255.0 * step(centerColor.g, topRightColor.g);
    greenByteTally += 2.0 / 255.0 * step(centerColor.g, topColor.g);
    greenByteTally += 4.0 / 255.0 * step(centerColor.g, topLeftColor.g);
    greenByteTally += 8.0 / 255.0 * step(centerColor.g, leftColor.g);
    greenByteTally += 16.0 / 255.0 * step(centerColor.g, bottomLeftColor.g);
    greenByteTally += 32.0 / 255.0 * step(centerColor.g, bottomColor.g);
    greenByteTally += 64.0 / 255.0 * step(centerColor.g, bottomRightColor.g);
    greenByteTally += 128.0 / 255.0 * step(centerColor.g, rightColor.g);
    
    // TODO: Replace the above with a dot product and two vec4s
    // TODO: Apply step to a matrix, rather than individually
    
    gl_FragColor = vec4(redByteTally, blueByteTally, greenByteTally, 1.0);
}
"""
public let ColorMatrixFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform mat4 colorMatrix;
uniform float intensity;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 outputColor = textureColor * colorMatrix;
    
    gl_FragColor = (intensity * outputColor) + ((1.0 - intensity) * textureColor);
}
"""
public let ColorSwizzlingFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate).bgra;
}
"""
public let ColourFASTDecriptorVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 textureCoordinate;
varying vec2 pointATextureCoordinate;
varying vec2 pointBTextureCoordinate;
varying vec2 pointCTextureCoordinate;
varying vec2 pointDTextureCoordinate;
varying vec2 pointETextureCoordinate;
varying vec2 pointFTextureCoordinate;
varying vec2 pointGTextureCoordinate;
varying vec2 pointHTextureCoordinate;

void main()
{
    gl_Position = position;
    
    float tripleTexelWidth = 3.0 * texelWidth;
    float tripleTexelHeight = 3.0 * texelHeight;
    
    textureCoordinate = inputTextureCoordinate.xy;
    
    pointATextureCoordinate = vec2(inputTextureCoordinate2.x + tripleTexelWidth, textureCoordinate.y + texelHeight);
    pointBTextureCoordinate = vec2(inputTextureCoordinate2.x + texelWidth, textureCoordinate.y + tripleTexelHeight);
    pointCTextureCoordinate = vec2(inputTextureCoordinate2.x - texelWidth, textureCoordinate.y + tripleTexelHeight);
    pointDTextureCoordinate = vec2(inputTextureCoordinate2.x - tripleTexelWidth, textureCoordinate.y + texelHeight);
    pointETextureCoordinate = vec2(inputTextureCoordinate2.x - tripleTexelWidth, textureCoordinate.y - texelHeight);
    pointFTextureCoordinate = vec2(inputTextureCoordinate2.x - texelWidth, textureCoordinate.y - tripleTexelHeight);
    pointGTextureCoordinate = vec2(inputTextureCoordinate2.x + texelWidth, textureCoordinate.y - tripleTexelHeight);
    pointHTextureCoordinate = vec2(inputTextureCoordinate2.x + tripleTexelWidth, textureCoordinate.y - texelHeight);
}
"""
public let ColourFASTDecriptorFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 pointATextureCoordinate;
varying vec2 pointBTextureCoordinate;
varying vec2 pointCTextureCoordinate;
varying vec2 pointDTextureCoordinate;
varying vec2 pointETextureCoordinate;
varying vec2 pointFTextureCoordinate;
varying vec2 pointGTextureCoordinate;
varying vec2 pointHTextureCoordinate;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;
const float PITwo = 6.2832;
const float PI = 3.1416;
void main()
{
    vec3 centerColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    
    vec3 pointAColor = texture2D(inputImageTexture2, pointATextureCoordinate).rgb;
    vec3 pointBColor = texture2D(inputImageTexture2, pointBTextureCoordinate).rgb;
    vec3 pointCColor = texture2D(inputImageTexture2, pointCTextureCoordinate).rgb;
    vec3 pointDColor = texture2D(inputImageTexture2, pointDTextureCoordinate).rgb;
    vec3 pointEColor = texture2D(inputImageTexture2, pointETextureCoordinate).rgb;
    vec3 pointFColor = texture2D(inputImageTexture2, pointFTextureCoordinate).rgb;
    vec3 pointGColor = texture2D(inputImageTexture2, pointGTextureCoordinate).rgb;
    vec3 pointHColor = texture2D(inputImageTexture2, pointHTextureCoordinate).rgb;
    
    vec3 colorComparison = ((pointAColor + pointBColor + pointCColor + pointDColor + pointEColor + pointFColor + pointGColor + pointHColor) * 0.125) - centerColor;
    
    // Direction calculation drawn from Appendix B of Seth Hall's Ph.D. thesis
    
    vec3 dirX = (pointAColor*0.94868) + (pointBColor*0.316227) - (pointCColor*0.316227) - (pointDColor*0.94868) - (pointEColor*0.94868) - (pointFColor*0.316227) + (pointGColor*0.316227) + (pointHColor*0.94868);
    vec3 dirY = (pointAColor*0.316227) + (pointBColor*0.94868) + (pointCColor*0.94868) + (pointDColor*0.316227) - (pointEColor*0.316227) - (pointFColor*0.94868) - (pointGColor*0.94868) - (pointHColor*0.316227);
    vec3 absoluteDifference = abs(colorComparison);
    float componentLength = length(colorComparison);
    float avgX = dot(absoluteDifference, dirX) / componentLength;
    float avgY = dot(absoluteDifference, dirY) / componentLength;
    float angle = atan(avgY, avgX);
    
    vec3 normalizedColorComparison = (colorComparison + 1.0) * 0.5;
    
    gl_FragColor = vec4(normalizedColorComparison, (angle+PI)/PITwo);
}
"""
public let ContrastFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float contrast;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(((textureColor.rgb - vec3(0.5)) * contrast + vec3(0.5)), textureColor.w);
}
"""
public let Convolution3x3FragmentShader = """
uniform sampler2D inputImageTexture;

uniform mat3 convolutionMatrix;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

void main()
{
    vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
    vec3 bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb;
    vec3 bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb;
    vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
    vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
    vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
    vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
    vec3 topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate).rgb;
    vec3 topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate).rgb;
    
    vec3 resultColor = topLeftColor * convolutionMatrix[0][0] + topColor * convolutionMatrix[0][1] + topRightColor * convolutionMatrix[0][2];
    resultColor += leftColor * convolutionMatrix[1][0] + centerColor.rgb * convolutionMatrix[1][1] + rightColor * convolutionMatrix[1][2];
    resultColor += bottomLeftColor * convolutionMatrix[2][0] + bottomColor * convolutionMatrix[2][1] + bottomRightColor * convolutionMatrix[2][2];
    
    gl_FragColor = vec4(resultColor, centerColor.a);
}
"""
public let CrosshairVertexShader = """
attribute vec4 position;

uniform float crosshairWidth;

varying vec2 centerLocation;
varying float pointSpacing;

void main()
{
    gl_Position = vec4(((position.xy * 2.0) - 1.0), 0.0, 1.0);
    gl_PointSize = crosshairWidth + 1.0;
    pointSpacing = 1.0 / crosshairWidth;
    centerLocation = vec2(pointSpacing * ceil(crosshairWidth / 2.0), pointSpacing * ceil(crosshairWidth / 2.0));
}
"""
public let CrosshairFragmentShader = """
#version 120

uniform vec3 crosshairColor;

varying vec2 centerLocation;
varying float pointSpacing;

void main()
{
    vec2 distanceFromCenter = abs(centerLocation - gl_PointCoord.xy);
    float axisTest = step(pointSpacing, gl_PointCoord.y) * step(distanceFromCenter.x, 0.09) + step(pointSpacing, gl_PointCoord.x) * step(distanceFromCenter.y, 0.09);
    
    gl_FragColor = vec4(crosshairColor * axisTest, axisTest);
    //     gl_FragColor = vec4(distanceFromCenterInX, distanceFromCenterInY, 0.0, 1.0);
}

"""
public let CrosshatchFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float crossHatchSpacing;
uniform float lineWidth;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    float luminance = dot(texture2D(inputImageTexture, textureCoordinate).rgb, W);
    
    vec4 colorToDisplay = vec4(1.0, 1.0, 1.0, 1.0);
    if (luminance < 1.00)
    {
        if (mod(textureCoordinate.x + textureCoordinate.y, crossHatchSpacing) <= lineWidth)
        {
            colorToDisplay = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.75)
    {
        if (mod(textureCoordinate.x - textureCoordinate.y, crossHatchSpacing) <= lineWidth)
        {
            colorToDisplay = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.50)
    {
        if (mod(textureCoordinate.x + textureCoordinate.y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth)
        {
            colorToDisplay = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
    if (luminance < 0.3)
    {
        if (mod(textureCoordinate.x - textureCoordinate.y - (crossHatchSpacing / 2.0), crossHatchSpacing) <= lineWidth)
        {
            colorToDisplay = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
    
    gl_FragColor = colorToDisplay;
}
"""
public let DarkenBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = vec4(min(overlayer.rgb * base.a, base.rgb * overlayer.a) + overlayer.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlayer.a), 1.0);
}
"""
public let DifferenceBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    gl_FragColor = vec4(abs(textureColor2.rgb - textureColor.rgb), textureColor.a);
}
"""
public let Dilation1FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    
    vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
    
    gl_FragColor = max(maxValue, oneStepNegativeIntensity);
}
"""
public let Dilation2FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
    vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
    
    vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
    maxValue = max(maxValue, oneStepNegativeIntensity);
    maxValue = max(maxValue, twoStepsPositiveIntensity);
    maxValue = max(maxValue, twoStepsNegativeIntensity);
    
    gl_FragColor = max(maxValue, twoStepsNegativeIntensity);
}
"""
public let Dilation3FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;
varying vec2 threeStepsPositiveTextureCoordinate;
varying vec2 threeStepsNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
    vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
    vec4 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate);
    vec4 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate);
    
    vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
    maxValue = max(maxValue, oneStepNegativeIntensity);
    maxValue = max(maxValue, twoStepsPositiveIntensity);
    maxValue = max(maxValue, twoStepsNegativeIntensity);
    maxValue = max(maxValue, threeStepsPositiveIntensity);
    
    gl_FragColor = max(maxValue, threeStepsNegativeIntensity);
}
"""
public let Dilation4FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;
varying vec2 threeStepsPositiveTextureCoordinate;
varying vec2 threeStepsNegativeTextureCoordinate;
varying vec2 fourStepsPositiveTextureCoordinate;
varying vec2 fourStepsNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
    vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
    vec4 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate);
    vec4 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate);
    vec4 fourStepsPositiveIntensity = texture2D(inputImageTexture, fourStepsPositiveTextureCoordinate);
    vec4 fourStepsNegativeIntensity = texture2D(inputImageTexture, fourStepsNegativeTextureCoordinate);
    
    vec4 maxValue = max(centerIntensity, oneStepPositiveIntensity);
    maxValue = max(maxValue, oneStepNegativeIntensity);
    maxValue = max(maxValue, twoStepsPositiveIntensity);
    maxValue = max(maxValue, twoStepsNegativeIntensity);
    maxValue = max(maxValue, threeStepsPositiveIntensity);
    maxValue = max(maxValue, threeStepsNegativeIntensity);
    maxValue = max(maxValue, fourStepsPositiveIntensity);
    
    gl_FragColor = max(maxValue, fourStepsNegativeIntensity);
}
"""
public let DirectionalNonMaximumSuppressionFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float texelWidth;
uniform float texelHeight;
uniform float upperThreshold;
uniform float lowerThreshold;

void main()
{
    vec3 currentGradientAndDirection = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec2 gradientDirection = ((currentGradientAndDirection.gb * 2.0) - 1.0) * vec2(texelWidth, texelHeight);
    
    float firstSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate + gradientDirection).r;
    float secondSampledGradientMagnitude = texture2D(inputImageTexture, textureCoordinate - gradientDirection).r;
    
    float multiplier = step(firstSampledGradientMagnitude, currentGradientAndDirection.r);
    multiplier = multiplier * step(secondSampledGradientMagnitude, currentGradientAndDirection.r);
    
    float thresholdCompliance = smoothstep(lowerThreshold, upperThreshold, currentGradientAndDirection.r);
    multiplier = multiplier * thresholdCompliance;
    
    gl_FragColor = vec4(multiplier, multiplier, multiplier, 1.0);
}
"""
public let DirectionalSobelEdgeDetectionFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    
    vec2 gradientDirection;
    gradientDirection.x = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    gradientDirection.y = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    
    float gradientMagnitude = length(gradientDirection);
    vec2 normalizedDirection = normalize(gradientDirection);
    normalizedDirection = sign(normalizedDirection) * floor(abs(normalizedDirection) + 0.617316); // Offset by 1-sin(pi/8) to set to 0 if near axis, 1 if away
    normalizedDirection = (normalizedDirection + 1.0) * 0.5; // Place -1.0 - 1.0 within 0 - 1.0
    
    gl_FragColor = vec4(gradientMagnitude, normalizedDirection.x, normalizedDirection.y, 1.0);
}
"""
public let DissolveBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;
uniform float mixturePercent;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = mix(textureColor, textureColor2, mixturePercent);
}
"""
public let DivideBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
 vec4 base = texture2D(inputImageTexture, textureCoordinate);
 vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
    
    float ra;
    if (overlay.a == 0.0 || ((base.r / overlay.r) > (base.a / overlay.a)))
        ra = overlay.a * base.a + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    else
        ra = (base.r * overlay.a * overlay.a) / overlay.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    
    
    float ga;
    if (overlay.a == 0.0 || ((base.g / overlay.g) > (base.a / overlay.a)))
        ga = overlay.a * base.a + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    else
        ga = (base.g * overlay.a * overlay.a) / overlay.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    
    
    float ba;
    if (overlay.a == 0.0 || ((base.b / overlay.b) > (base.a / overlay.a)))
        ba = overlay.a * base.a + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    else
        ba = (base.b * overlay.a * overlay.a) / overlay.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    
    float a = overlay.a + base.a - overlay.a * base.a;
    
 gl_FragColor = vec4(ra, ga, ba, a);
}
"""
public let Erosion1FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    
    vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
    
    gl_FragColor = min(minValue, oneStepNegativeIntensity);
}
"""
public let Erosion2FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
    vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
    
    vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
    minValue = min(minValue, oneStepNegativeIntensity);
    minValue = min(minValue, twoStepsPositiveIntensity);
    
    gl_FragColor = min(minValue, twoStepsNegativeIntensity);
}
"""
public let Erosion3FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;
varying vec2 threeStepsPositiveTextureCoordinate;
varying vec2 threeStepsNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
    vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
    vec4 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate);
    vec4 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate);
    
    vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
    minValue = min(minValue, oneStepNegativeIntensity);
    minValue = min(minValue, twoStepsPositiveIntensity);
    minValue = min(minValue, twoStepsNegativeIntensity);
    minValue = min(minValue, threeStepsPositiveIntensity);
    
    gl_FragColor = min(minValue, threeStepsNegativeIntensity);
}
"""
public let Erosion4FragmentShader = """
varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;
varying vec2 threeStepsPositiveTextureCoordinate;
varying vec2 threeStepsNegativeTextureCoordinate;
varying vec2 fourStepsPositiveTextureCoordinate;
varying vec2 fourStepsNegativeTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    vec4 centerIntensity = texture2D(inputImageTexture, centerTextureCoordinate);
    vec4 oneStepPositiveIntensity = texture2D(inputImageTexture, oneStepPositiveTextureCoordinate);
    vec4 oneStepNegativeIntensity = texture2D(inputImageTexture, oneStepNegativeTextureCoordinate);
    vec4 twoStepsPositiveIntensity = texture2D(inputImageTexture, twoStepsPositiveTextureCoordinate);
    vec4 twoStepsNegativeIntensity = texture2D(inputImageTexture, twoStepsNegativeTextureCoordinate);
    vec4 threeStepsPositiveIntensity = texture2D(inputImageTexture, threeStepsPositiveTextureCoordinate);
    vec4 threeStepsNegativeIntensity = texture2D(inputImageTexture, threeStepsNegativeTextureCoordinate);
    vec4 fourStepsPositiveIntensity = texture2D(inputImageTexture, fourStepsPositiveTextureCoordinate);
    vec4 fourStepsNegativeIntensity = texture2D(inputImageTexture, fourStepsNegativeTextureCoordinate);
    
    vec4 minValue = min(centerIntensity, oneStepPositiveIntensity);
    minValue = min(minValue, oneStepNegativeIntensity);
    minValue = min(minValue, twoStepsPositiveIntensity);
    minValue = min(minValue, twoStepsNegativeIntensity);
    minValue = min(minValue, threeStepsPositiveIntensity);
    minValue = min(minValue, threeStepsNegativeIntensity);
    minValue = min(minValue, fourStepsPositiveIntensity);
    
    gl_FragColor = min(minValue, fourStepsNegativeIntensity);
}
"""
public let ErosionDilation1VertexShader = """
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth; 
uniform float texelHeight; 

varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 offset = vec2(texelWidth, texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
    oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
}
"""
public let ErosionDilation2VertexShader = """
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 offset = vec2(texelWidth, texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
    oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
    twoStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 2.0);
    twoStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 2.0);
}
"""
public let ErosionDilation3VertexShader = """
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;
varying vec2 threeStepsPositiveTextureCoordinate;
varying vec2 threeStepsNegativeTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 offset = vec2(texelWidth, texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
    oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
    twoStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 2.0);
    twoStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 2.0);
    threeStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 3.0);
    threeStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 3.0);
}
"""
public let ErosionDilation4VertexShader = """
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepPositiveTextureCoordinate;
varying vec2 oneStepNegativeTextureCoordinate;
varying vec2 twoStepsPositiveTextureCoordinate;
varying vec2 twoStepsNegativeTextureCoordinate;
varying vec2 threeStepsPositiveTextureCoordinate;
varying vec2 threeStepsNegativeTextureCoordinate;
varying vec2 fourStepsPositiveTextureCoordinate;
varying vec2 fourStepsNegativeTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 offset = vec2(texelWidth, texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepNegativeTextureCoordinate = inputTextureCoordinate - offset;
    oneStepPositiveTextureCoordinate = inputTextureCoordinate + offset;
    twoStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 2.0);
    twoStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 2.0);
    threeStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 3.0);
    threeStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 3.0);
    fourStepsNegativeTextureCoordinate = inputTextureCoordinate - (offset * 4.0);
    fourStepsPositiveTextureCoordinate = inputTextureCoordinate + (offset * 4.0);
}
"""
public let ExclusionBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
    
    //     Dca = (Sca.Da + Dca.Sa - 2.Sca.Dca) + Sca.(1 - Da) + Dca.(1 - Sa)
    
    gl_FragColor = vec4((overlay.rgb * base.a + base.rgb * overlay.a - 2.0 * overlay.rgb * base.rgb) + overlay.rgb * (1.0 - base.a) + base.rgb * (1.0 - overlay.a), base.a);
}
"""
public let ExposureFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float exposure;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.rgb * pow(2.0, exposure), textureColor.w);
}
"""
public let FalseColorFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float intensity;
uniform vec3 firstColor;
uniform vec3 secondColor;

const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    
    gl_FragColor = vec4( mix(firstColor.rgb, secondColor.rgb, luminance), textureColor.a);
}
"""
public let FiveInputVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;
attribute vec4 inputTextureCoordinate3;
attribute vec4 inputTextureCoordinate4;
attribute vec4 inputTextureCoordinate5;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;
varying vec2 textureCoordinate3;
varying vec2 textureCoordinate4;
varying vec2 textureCoordinate5;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    textureCoordinate2 = inputTextureCoordinate2.xy;
    textureCoordinate3 = inputTextureCoordinate3.xy;
    textureCoordinate4 = inputTextureCoordinate4.xy;
    textureCoordinate5 = inputTextureCoordinate5.xy;
}
"""
public let FourInputVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;
attribute vec4 inputTextureCoordinate3;
attribute vec4 inputTextureCoordinate4;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;
varying vec2 textureCoordinate3;
varying vec2 textureCoordinate4;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    textureCoordinate2 = inputTextureCoordinate2.xy;
    textureCoordinate3 = inputTextureCoordinate3.xy;
    textureCoordinate4 = inputTextureCoordinate4.xy;
}
"""
public let GammaFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float gamma;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(pow(textureColor.rgb, vec3(gamma)), textureColor.w);
}
"""
public let GlassSphereFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 center;
uniform float radius;
uniform float aspectRatio;
uniform float refractiveIndex;
// uniform vec3 lightPosition;
const vec3 lightPosition = vec3(-0.5, 0.5, 1.0);
const vec3 ambientLightPosition = vec3(0.0, 0.0, 1.0);

void main()
{
    vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    float distanceFromCenter = distance(center, textureCoordinateToUse);
    float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
    
    distanceFromCenter = distanceFromCenter / radius;
    
    float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
    vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));
    
    vec3 refractedVector = 2.0 * refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
    refractedVector.xy = -refractedVector.xy;
    
    vec3 finalSphereColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5).rgb;
    
    // Grazing angle lighting
    float lightingIntensity = 2.5 * (1.0 - pow(clamp(dot(ambientLightPosition, sphereNormal), 0.0, 1.0), 0.25));
    finalSphereColor += lightingIntensity;
    
    // Specular lighting
    lightingIntensity  = clamp(dot(normalize(lightPosition), sphereNormal), 0.0, 1.0);
    lightingIntensity  = pow(lightingIntensity, 15.0);
    finalSphereColor += vec3(0.8, 0.8, 0.8) * lightingIntensity;
    
    gl_FragColor = vec4(finalSphereColor, 1.0) * checkForPresenceWithinSphere;
}
"""
public let HalftoneFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float fractionalWidthOfPixel;
uniform float aspectRatio;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
    
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
    vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
    
    vec3 sampledColor = texture2D(inputImageTexture, samplePos ).rgb;
    float dotScaling = 1.0 - dot(sampledColor, W);
    
    float checkForPresenceWithinDot = 1.0 - step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);
    
    gl_FragColor = vec4(vec3(checkForPresenceWithinDot), 1.0);
}
"""
public let HardLightBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
    
    float ra;
    if (2.0 * overlay.r < overlay.a) {
        ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    }
    
    float ga;
    if (2.0 * overlay.g < overlay.a) {
        ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    }
    
    float ba;
    if (2.0 * overlay.b < overlay.a) {
        ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    }
    
    gl_FragColor = vec4(ra, ga, ba, 1.0);
}
"""
public let HarrisCornerDetectorFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float sensitivity;

const float harrisConstant = 0.04;

void main()
{
    vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
    
    float derivativeSum = derivativeElements.x + derivativeElements.y;
    
    float zElement = (derivativeElements.z * 2.0) - 1.0;
    
    // R = Ix^2 * Iy^2 - Ixy * Ixy - k * (Ix^2 + Iy^2)^2
    float cornerness = derivativeElements.x * derivativeElements.y - (zElement * zElement) - harrisConstant * derivativeSum * derivativeSum;
    
    gl_FragColor = vec4(vec3(cornerness * sensitivity), 1.0);
}
"""
public let HazeFragmentShader = """
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
"""
public let HighlightShadowTintFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float shadowTintIntensity;
uniform float highlightTintIntensity;
uniform vec3 shadowTintColor;
uniform vec3 highlightTintColor;

const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
   vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   float luminance = dot(textureColor.rgb, luminanceWeighting);
    
   vec4 shadowResult = mix(textureColor, max(textureColor, vec4( mix(shadowTintColor, textureColor.rgb, luminance), textureColor.a)), shadowTintIntensity);
   vec4 highlightResult = mix(textureColor, min(shadowResult, vec4( mix(shadowResult.rgb, highlightTintColor.rgb, luminance), textureColor.a)), highlightTintIntensity);
    
   gl_FragColor = vec4( mix(shadowResult.rgb, highlightResult.rgb, luminance), textureColor.a);
}
"""
public let HighlightShadowFragmentShader = """
uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

uniform float shadows;
uniform float highlights;

const vec3 luminanceWeighting = vec3(0.3, 0.3, 0.3);

void main()
{
    vec4 source = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(source.rgb, luminanceWeighting);
   
    float shadow = clamp((pow(luminance, 1.0/(shadows+1.0)) + (-0.76)*pow(luminance, 2.0/(shadows+1.0))) - luminance, 0.0, 1.0);
    float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-highlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-highlights)))) - luminance, -1.0, 0.0);
    vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((source.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));

    gl_FragColor = vec4(result.rgb, source.a);
}
"""
public let HistogramAccumulationFragmentShader = """
const float scalingFactor = 1.0 / 256.0;

varying vec3 colorFactor;

void main()
{
    gl_FragColor = vec4(colorFactor * scalingFactor , 1.0);
}
"""
public let HistogramBlueSamplingVertexShader = """
attribute vec4 position;

varying vec3 colorFactor;

void main()
{
    colorFactor = vec3(0.0, 0.0, 1.0);
    gl_Position = vec4(-1.0 + (position.z * 0.0078125), 0.0, 0.0, 1.0);
    gl_PointSize = 1.0;
}
"""
public let HistogramDisplayVertexShader = """
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
"""
public let HistogramDisplayFragmentShader = """
varying vec2 textureCoordinate;
varying float height;

uniform sampler2D inputImageTexture;
vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 0.0);

void main()
{
    vec3 colorChannels = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec4 heightTest = vec4(step(height, colorChannels), 1.0);
    gl_FragColor = mix(backgroundColor, heightTest, heightTest.r + heightTest.g + heightTest.b);
}
"""
public let HistogramEqualizationBlueFragmentShader = """
varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
    
    gl_FragColor = vec4(textureColor.r, textureColor.g, blueCurveValue, textureColor.a);
}
"""
public let HistogramEqualizationGreenFragmentShader = """
varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
    
    gl_FragColor = vec4(textureColor.r, greenCurveValue, textureColor.b, textureColor.a);
}
"""
public let HistogramEqualizationLuminanceFragmentShader = """
varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, W);
    float newLuminance = texture2D(inputImageTexture2, vec2(luminance, 0.0)).r;
    float deltaLuminance = newLuminance - luminance;
    
    float red   = clamp(textureColor.r + deltaLuminance, 0.0, 1.0);
    float green = clamp(textureColor.g + deltaLuminance, 0.0, 1.0);
    float blue  = clamp(textureColor.b + deltaLuminance, 0.0, 1.0);
    
    gl_FragColor = vec4(red, green, blue, textureColor.a);
}
"""
public let HistogramEqualizationRGBFragmentShader = """
varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
    float greenCurveValue = texture2D(inputImageTexture2, vec2(textureColor.g, 0.0)).g;
    float blueCurveValue = texture2D(inputImageTexture2, vec2(textureColor.b, 0.0)).b;
    
    gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
}
"""
public let HistogramEqualizationRedFragmentShader = """
varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float redCurveValue = texture2D(inputImageTexture2, vec2(textureColor.r, 0.0)).r;
    
    gl_FragColor = vec4(redCurveValue, textureColor.g, textureColor.b, textureColor.a);
}
"""
public let HistogramGreenSamplingVertexShader = """
attribute vec4 position;

varying vec3 colorFactor;

void main()
{
    colorFactor = vec3(0.0, 1.0, 0.0);
    gl_Position = vec4(-1.0 + (position.y * 0.0078125), 0.0, 0.0, 1.0);
    gl_PointSize = 1.0;
}
"""
public let HistogramLuminanceSamplingVertexShader = """
attribute vec4 position;

varying vec3 colorFactor;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    float luminance = dot(position.xyz, W);

    colorFactor = vec3(1.0, 1.0, 1.0);
    gl_Position = vec4(-1.0 + (luminance * 0.0078125), 0.0, 0.0, 1.0);
    gl_PointSize = 1.0;
}
"""
public let HistogramRedSamplingVertexShader = """
attribute vec4 position;

varying vec3 colorFactor;

void main()
{
    colorFactor = vec3(1.0, 0.0, 0.0);
    gl_Position = vec4(-1.0 + (position.x * 0.0078125), 0.0, 0.0, 1.0);
    gl_PointSize = 1.0;
}
"""
public let HueBlendFragmentShader = """
// Hue blend mode based upon pseudo code from the PDF specification.

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

float lum(vec3 c) {
    return dot(c, vec3(0.3, 0.59, 0.11));
}

vec3 clipcolor(vec3 c) {
    float l = lum(c);
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    
    if (n < 0.0) {
        c.r = l + ((c.r - l) * l) / (l - n);
        c.g = l + ((c.g - l) * l) / (l - n);
        c.b = l + ((c.b - l) * l) / (l - n);
    }
    if (x > 1.0) {
        c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
        c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
        c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
    }
    
    return c;
}

vec3 setlum(vec3 c, float l) {
    float d = l - lum(c);
    c = c + vec3(d);
    return clipcolor(c);
}

float sat(vec3 c) {
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    return x - n;
}

float mid(float cmin, float cmid, float cmax, float s) {
    return ((cmid - cmin) * s) / (cmax - cmin);
}

vec3 setsat(vec3 c, float s) {
    if (c.r > c.g) {
        if (c.r > c.b) {
            if (c.g > c.b) {
                /* g is mid, b is min */
                c.g = mid(c.b, c.g, c.r, s);
                c.b = 0.0;
            } else {
                /* b is mid, g is min */
                c.b = mid(c.g, c.b, c.r, s);
                c.g = 0.0;
            }
            c.r = s;
        } else {
            /* b is max, r is mid, g is min */
            c.r = mid(c.g, c.r, c.b, s);
            c.b = s;
            c.r = 0.0;
        }
    } else if (c.r > c.b) {
        /* g is max, r is mid, b is min */
        c.r = mid(c.b, c.r, c.g, s);
        c.g = s;
        c.b = 0.0;
    } else if (c.g > c.b) {
        /* g is max, b is mid, r is min */
        c.b = mid(c.r, c.b, c.g, s);
        c.g = s;
        c.r = 0.0;
    } else if (c.b > c.g) {
        /* b is max, g is mid, r is min */
        c.g = mid(c.r, c.g, c.b, s);
        c.b = s;
        c.r = 0.0;
    } else {
        c = vec3(0.0);
    }
    return c;
}

void main()
{
 vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(setsat(overlayColor.rgb, sat(baseColor.rgb)), lum(baseColor.rgb)) * overlayColor.a, baseColor.a);
}
"""
public let HueFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float hueAdjust;
const vec4  kRGBToYPrime = vec4 (0.299, 0.587, 0.114, 0.0);
const vec4  kRGBToI     = vec4 (0.595716, -0.274453, -0.321263, 0.0);
const vec4  kRGBToQ     = vec4 (0.211456, -0.522591, 0.31135, 0.0);

const vec4  kYIQToR   = vec4 (1.0, 0.9563, 0.6210, 0.0);
const vec4  kYIQToG   = vec4 (1.0, -0.2721, -0.6474, 0.0);
const vec4  kYIQToB   = vec4 (1.0, -1.1070, 1.7046, 0.0);

void main ()
{
    // Sample the input pixel
    vec4 color   = texture2D(inputImageTexture, textureCoordinate);
    
    // Convert to YIQ
    float   YPrime  = dot (color, kRGBToYPrime);
    float   I      = dot (color, kRGBToI);
    float   Q      = dot (color, kRGBToQ);
    
    // Calculate the hue and chroma
    float   hue     = atan (Q, I);
    float   chroma  = sqrt (I * I + Q * Q);
    
    // Make the user's adjustments
    hue += (-hueAdjust); //why negative rotation?
    
    // Convert back to YIQ
    Q = chroma * sin (hue);
    I = chroma * cos (hue);
    
    // Convert back to RGB
    vec4    yIQ   = vec4 (YPrime, I, Q, 0.0);
    color.r = dot (yIQ, kYIQToR);
    color.g = dot (yIQ, kYIQToG);
    color.b = dot (yIQ, kYIQToB);
    
    // Save the result
    gl_FragColor = color;
}
"""
public let KuwaharaRadius3FragmentShader = """
// Sourced from Kyprianidis, J. E., Kang, H., and Doellner, J. "Anisotropic Kuwahara Filtering on the GPU," GPU Pro p.247 (2010).
// 
// Original header:
// 
// Anisotropic Kuwahara Filtering on the GPU
// by Jan Eric Kyprianidis <www.kyprianidis.com>

varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;

const vec2 src_size = vec2 (1.0 / 768.0, 1.0 / 1024.0);

void main (void)
{
    vec2 uv = textureCoordinate;
    float n = float(16); // radius is assumed to be 3
    vec3 m0 = vec3(0.0); vec3 m1 = vec3(0.0); vec3 m2 = vec3(0.0); vec3 m3 = vec3(0.0);
    vec3 s0 = vec3(0.0); vec3 s1 = vec3(0.0); vec3 s2 = vec3(0.0); vec3 s3 = vec3(0.0);
    vec3 c;
    vec3 cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(-3,-3) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-3,-2) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-3,-1) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-3,0) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m1 += c;
    s1 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(-2,-3) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-2,-2) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-2,-1) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-2,0) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m1 += c;
    s1 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(-1,-3) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-1,-2) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-1,-1) * src_size).rgb;
    m0 += c;
    s0 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-1,0) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m1 += c;
    s1 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(0,-3) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m3 += c;
    s3 += cSq;
    c = texture2D(inputImageTexture, uv + vec2(0,-2) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m3 += c;
    s3 += cSq;
    c = texture2D(inputImageTexture, uv + vec2(0,-1) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m3 += c;
    s3 += cSq;
    c = texture2D(inputImageTexture, uv + vec2(0,0) * src_size).rgb;
    cSq = c * c;
    m0 += c;
    s0 += cSq;
    m1 += c;
    s1 += cSq;
    m2 += c;
    s2 += cSq;
    m3 += c;
    s3 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(-3,3) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-3,2) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-3,1) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    
    c = texture2D(inputImageTexture, uv + vec2(-2,3) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-2,2) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-2,1) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    
    c = texture2D(inputImageTexture, uv + vec2(-1,3) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-1,2) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(-1,1) * src_size).rgb;
    m1 += c;
    s1 += c * c;
    
    c = texture2D(inputImageTexture, uv + vec2(0,3) * src_size).rgb;
    cSq = c * c;
    m1 += c;
    s1 += cSq;
    m2 += c;
    s2 += cSq;
    c = texture2D(inputImageTexture, uv + vec2(0,2) * src_size).rgb;
    cSq = c * c;
    m1 += c;
    s1 += cSq;
    m2 += c;
    s2 += cSq;
    c = texture2D(inputImageTexture, uv + vec2(0,1) * src_size).rgb;
    cSq = c * c;
    m1 += c;
    s1 += cSq;
    m2 += c;
    s2 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(3,3) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(3,2) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(3,1) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(3,0) * src_size).rgb;
    cSq = c * c;
    m2 += c;
    s2 += cSq;
    m3 += c;
    s3 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(2,3) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(2,2) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(2,1) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(2,0) * src_size).rgb;
    cSq = c * c;
    m2 += c;
    s2 += cSq;
    m3 += c;
    s3 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(1,3) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(1,2) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(1,1) * src_size).rgb;
    m2 += c;
    s2 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(1,0) * src_size).rgb;
    cSq = c * c;
    m2 += c;
    s2 += cSq;
    m3 += c;
    s3 += cSq;
    
    c = texture2D(inputImageTexture, uv + vec2(3,-3) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(3,-2) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(3,-1) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    
    c = texture2D(inputImageTexture, uv + vec2(2,-3) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(2,-2) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(2,-1) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    
    c = texture2D(inputImageTexture, uv + vec2(1,-3) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(1,-2) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    c = texture2D(inputImageTexture, uv + vec2(1,-1) * src_size).rgb;
    m3 += c;
    s3 += c * c;
    
    float min_sigma2 = 1e+2;
    m0 /= n;
    s0 = abs(s0 / n - m0 * m0);
    
    float sigma2 = s0.r + s0.g + s0.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m0, 1.0);
    }
    
    m1 /= n;
    s1 = abs(s1 / n - m1 * m1);
    
    sigma2 = s1.r + s1.g + s1.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m1, 1.0);
    }
    
    m2 /= n;
    s2 = abs(s2 / n - m2 * m2);
    
    sigma2 = s2.r + s2.g + s2.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m2, 1.0);
    }
    
    m3 /= n;
    s3 = abs(s3 / n - m3 * m3);
    
    sigma2 = s3.r + s3.g + s3.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m3, 1.0);
    }
}
"""
public let KuwaharaFragmentShader = """
// Sourced from Kyprianidis, J. E., Kang, H., and Doellner, J. "Anisotropic Kuwahara Filtering on the GPU," GPU Pro p.247 (2010).
// 
// Original header:
// 
// Anisotropic Kuwahara Filtering on the GPU
// by Jan Eric Kyprianidis <www.kyprianidis.com>

varying vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform int radius;

const vec2 src_size = vec2 (1.0 / 768.0, 1.0 / 1024.0);

void main (void)
{
    vec2 uv = textureCoordinate;
    float n = float((radius + 1) * (radius + 1));
    int i; int j;
    vec3 m0 = vec3(0.0); vec3 m1 = vec3(0.0); vec3 m2 = vec3(0.0); vec3 m3 = vec3(0.0);
    vec3 s0 = vec3(0.0); vec3 s1 = vec3(0.0); vec3 s2 = vec3(0.0); vec3 s3 = vec3(0.0);
    vec3 c;
    
    for (j = -radius; j <= 0; ++j)  {
        for (i = -radius; i <= 0; ++i)  {
            c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
            m0 += c;
            s0 += c * c;
        }
    }
    
    for (j = -radius; j <= 0; ++j)  {
        for (i = 0; i <= radius; ++i)  {
            c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
            m1 += c;
            s1 += c * c;
        }
    }
    
    for (j = 0; j <= radius; ++j)  {
        for (i = 0; i <= radius; ++i)  {
            c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
            m2 += c;
            s2 += c * c;
        }
    }
    
    for (j = 0; j <= radius; ++j)  {
        for (i = -radius; i <= 0; ++i)  {
            c = texture2D(inputImageTexture, uv + vec2(i,j) * src_size).rgb;
            m3 += c;
            s3 += c * c;
        }
    }
    
    
    float min_sigma2 = 1e+2;
    m0 /= n;
    s0 = abs(s0 / n - m0 * m0);
    
    float sigma2 = s0.r + s0.g + s0.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m0, 1.0);
    }
    
    m1 /= n;
    s1 = abs(s1 / n - m1 * m1);
    
    sigma2 = s1.r + s1.g + s1.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m1, 1.0);
    }
    
    m2 /= n;
    s2 = abs(s2 / n - m2 * m2);
    
    sigma2 = s2.r + s2.g + s2.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m2, 1.0);
    }
    
    m3 /= n;
    s3 = abs(s3 / n - m3 * m3);
    
    sigma2 = s3.r + s3.g + s3.b;
    if (sigma2 < min_sigma2) {
        min_sigma2 = sigma2;
        gl_FragColor = vec4(m3, 1.0);
    }
}
"""
public let LanczosResamplingVertexShader = """
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepLeftTextureCoordinate;
varying vec2 twoStepsLeftTextureCoordinate;
varying vec2 threeStepsLeftTextureCoordinate;
varying vec2 fourStepsLeftTextureCoordinate;
varying vec2 oneStepRightTextureCoordinate;
varying vec2 twoStepsRightTextureCoordinate;
varying vec2 threeStepsRightTextureCoordinate;
varying vec2 fourStepsRightTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 firstOffset = vec2(texelWidth, texelHeight);
    vec2 secondOffset = vec2(2.0 * texelWidth, 2.0 * texelHeight);
    vec2 thirdOffset = vec2(3.0 * texelWidth, 3.0 * texelHeight);
    vec2 fourthOffset = vec2(4.0 * texelWidth, 4.0 * texelHeight);
    
    centerTextureCoordinate = inputTextureCoordinate;
    oneStepLeftTextureCoordinate = inputTextureCoordinate - firstOffset;
    twoStepsLeftTextureCoordinate = inputTextureCoordinate - secondOffset;
    threeStepsLeftTextureCoordinate = inputTextureCoordinate - thirdOffset;
    fourStepsLeftTextureCoordinate = inputTextureCoordinate - fourthOffset;
    oneStepRightTextureCoordinate = inputTextureCoordinate + firstOffset;
    twoStepsRightTextureCoordinate = inputTextureCoordinate + secondOffset;
    threeStepsRightTextureCoordinate = inputTextureCoordinate + thirdOffset;
    fourStepsRightTextureCoordinate = inputTextureCoordinate + fourthOffset;
}
"""
public let LanczosResamplingFragmentShader = """
uniform sampler2D inputImageTexture;

varying vec2 centerTextureCoordinate;
varying vec2 oneStepLeftTextureCoordinate;
varying vec2 twoStepsLeftTextureCoordinate;
varying vec2 threeStepsLeftTextureCoordinate;
varying vec2 fourStepsLeftTextureCoordinate;
varying vec2 oneStepRightTextureCoordinate;
varying vec2 twoStepsRightTextureCoordinate;
varying vec2 threeStepsRightTextureCoordinate;
varying vec2 fourStepsRightTextureCoordinate;

// sinc(x) * sinc(x/a) = (a * sin(pi * x) * sin(pi * x / a)) / (pi^2 * x^2)
// Assuming a Lanczos constant of 2.0, and scaling values to max out at x = +/- 1.5

void main()
{
    vec4 fragmentColor = texture2D(inputImageTexture, centerTextureCoordinate) * 0.38026;
    
    fragmentColor += texture2D(inputImageTexture, oneStepLeftTextureCoordinate) * 0.27667;
    fragmentColor += texture2D(inputImageTexture, oneStepRightTextureCoordinate) * 0.27667;
    
    fragmentColor += texture2D(inputImageTexture, twoStepsLeftTextureCoordinate) * 0.08074;
    fragmentColor += texture2D(inputImageTexture, twoStepsRightTextureCoordinate) * 0.08074;
    
    fragmentColor += texture2D(inputImageTexture, threeStepsLeftTextureCoordinate) * -0.02612;
    fragmentColor += texture2D(inputImageTexture, threeStepsRightTextureCoordinate) * -0.02612;
    
    fragmentColor += texture2D(inputImageTexture, fourStepsLeftTextureCoordinate) * -0.02143;
    fragmentColor += texture2D(inputImageTexture, fourStepsRightTextureCoordinate) * -0.02143;
    
    gl_FragColor = fragmentColor;
}
"""
public let LaplacianFragmentShader = """
uniform sampler2D inputImageTexture;

uniform mat3 convolutionMatrix;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

void main()
{
    vec3 bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
    vec3 bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb;
    vec3 bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb;
    vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
    vec3 leftColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
    vec3 rightColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
    vec3 topColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
    vec3 topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate).rgb;
    vec3 topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate).rgb;
    
    vec3 resultColor = topLeftColor * 0.5 + topColor * 1.0 + topRightColor * 0.5;
    resultColor += leftColor * 1.0 + centerColor.rgb * (-6.0) + rightColor * 1.0;
    resultColor += bottomLeftColor * 0.5 + bottomColor * 1.0 + bottomRightColor * 0.5;
    
    // Normalize the results to allow for negative gradients in the 0.0-1.0 colorspace
    resultColor = resultColor + 0.5;

    gl_FragColor = vec4(resultColor, centerColor.a);
}
"""
public let LevelsFragmentShader = """
/*
 ** Gamma correction
 ** Details: http://blog.mouaif.org/2009/01/22/photoshop-gamma-correction-shader/
 */

#define GammaCorrection(color, gamma)  pow(color, 1.0 / gamma)

/*
 ** Levels control (input (+gamma), output)
 ** Details: http://blog.mouaif.org/2009/01/28/levels-control-shader/
 */

#define LevelsControlInputRange(color, minInput, maxInput)     min(max(color - minInput, vec3(0.0)) / (maxInput - minInput), vec3(1.0))
#define LevelsControlInput(color, minInput, gamma, maxInput)   GammaCorrection(LevelsControlInputRange(color, minInput, maxInput), gamma)
#define LevelsControlOutputRange(color, minOutput, maxOutput)   mix(minOutput, maxOutput, color)
#define LevelsControl(color, minInput, gamma, maxInput, minOutput, maxOutput)  LevelsControlOutputRange(LevelsControlInput(color, minInput, gamma, maxInput), minOutput, maxOutput)

varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform vec3 levelMinimum;
uniform vec3 levelMiddle;
uniform vec3 levelMaximum;
uniform vec3 minOutput;
uniform vec3 maxOutput;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(LevelsControl(textureColor.rgb, levelMinimum, levelMiddle, levelMaximum, minOutput, maxOutput), textureColor.a);
}

"""
public let LightenBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = max(textureColor, textureColor2);
}
"""
public let LineVertexShader = """
attribute vec4 position;

void main()
{
    gl_Position = position;
}
"""
public let LineFragmentShader = """
uniform vec3 lineColor;

void main()
{
    gl_FragColor = vec4(lineColor, 1.0);
}
"""
public let LinearBurnBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = vec4(clamp(textureColor.rgb + textureColor2.rgb - vec3(1.0), vec3(0.0), vec3(1.0)), textureColor.a);
}
"""
public let LocalBinaryPatternFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    float centerIntensity = texture2D(inputImageTexture, textureCoordinate).r;
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    
    float byteTally = 1.0 / 255.0 * step(centerIntensity, topRightIntensity);
    byteTally += 2.0 / 255.0 * step(centerIntensity, topIntensity);
    byteTally += 4.0 / 255.0 * step(centerIntensity, topLeftIntensity);
    byteTally += 8.0 / 255.0 * step(centerIntensity, leftIntensity);
    byteTally += 16.0 / 255.0 * step(centerIntensity, bottomLeftIntensity);
    byteTally += 32.0 / 255.0 * step(centerIntensity, bottomIntensity);
    byteTally += 64.0 / 255.0 * step(centerIntensity, bottomRightIntensity);
    byteTally += 128.0 / 255.0 * step(centerIntensity, rightIntensity);
    
    // TODO: Replace the above with a dot product and two vec4s
    // TODO: Apply step to a matrix, rather than individually
    
    gl_FragColor = vec4(byteTally, byteTally, byteTally, 1.0);
}
"""
public let LookupFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2; // lookup texture

uniform float intensity;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    float blueColor = textureColor.b * 63.0;
    
    vec2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
    
    vec2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);
    
    vec2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
    
    vec2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
    
    vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
    vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
    
    vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
    gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
}
"""
public let LuminanceRangeFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float rangeReduction;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    float luminanceRatio = ((0.5 - luminance) * rangeReduction);
    
    gl_FragColor = vec4((textureColor.rgb) + (luminanceRatio), textureColor.w);
}
"""
public let LuminanceThresholdFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float threshold;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, W);
    float thresholdResult = step(threshold, luminance);
    
    gl_FragColor = vec4(vec3(thresholdResult), textureColor.w);
}
"""
public let LuminanceFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, W);
    
    gl_FragColor = vec4(vec3(luminance), textureColor.a);
}
"""
public let LuminosityBlendFragmentShader = """
// Luminosity blend mode based upon pseudo code from the PDF specification.

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

float lum(vec3 c) {
    return dot(c, vec3(0.3, 0.59, 0.11));
}

vec3 clipcolor(vec3 c) {
    float l = lum(c);
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    
    if (n < 0.0) {
        c.r = l + ((c.r - l) * l) / (l - n);
        c.g = l + ((c.g - l) * l) / (l - n);
        c.b = l + ((c.b - l) * l) / (l - n);
    }
    if (x > 1.0) {
        c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
        c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
        c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
    }
    
    return c;
}

vec3 setlum(vec3 c, float l) {
    float d = l - lum(c);
    c = c + vec3(d);
    return clipcolor(c);
}

void main()
{
 vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(baseColor.rgb, lum(overlayColor.rgb)) * overlayColor.a, baseColor.a);
}
"""
public let MedianFragmentShader = """
/*
 3x3 median filter, adapted from "A Fast, Small-Radius GPU Median Filter" by Morgan McGuire in ShaderX6
 http://graphics.cs.williams.edu/papers/MedianShaderX6/
 
 Morgan McGuire and Kyle Whitson
 Williams College
 
 Register allocation tips by Victor Huang Xiaohuang
 University of Illinois at Urbana-Champaign
 
 http://graphics.cs.williams.edu
 
 
 Copyright (c) Morgan McGuire and Williams College, 2006
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
 Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
#define s2(a, b)                temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c)            s2(a, b); s2(a, c);
#define mx3(a, b, c)            s2(b, c); s2(a, c);
 
#define mnmx3(a, b, c)          mx3(a, b, c); s2(a, b);                                   // 3 exchanges
#define mnmx4(a, b, c, d)       s2(a, b); s2(c, d); s2(a, c); s2(b, d);                   // 4 exchanges
#define mnmx5(a, b, c, d, e)    s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f); // 7 exchanges
 
 void main()
 {
     vec3 v[6];
     
     v[0] = texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb;
     v[1] = texture2D(inputImageTexture, topRightTextureCoordinate).rgb;
     v[2] = texture2D(inputImageTexture, topLeftTextureCoordinate).rgb;
     v[3] = texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb;
     v[4] = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
     v[5] = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
     //     v[6] = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
     //     v[7] = texture2D(inputImageTexture, topTextureCoordinate).rgb;
     vec3 temp;
     
     mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
     
     v[5] = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
     
     mnmx5(v[1], v[2], v[3], v[4], v[5]);
     
     v[5] = texture2D(inputImageTexture, topTextureCoordinate).rgb;
     
     mnmx4(v[2], v[3], v[4], v[5]);
     
     v[5] = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     mnmx3(v[3], v[4], v[5]);
     
     gl_FragColor = vec4(v[4], 1.0);
 }
"""
public let MonochromeFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float intensity;
uniform vec3 filterColor;

const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    //desat, then apply overlay blend
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    
    vec4 desat = vec4(vec3(luminance), 1.0);
    
    //overlay
    vec4 outputColor = vec4(
                                 (desat.r < 0.5 ? (2.0 * desat.r * filterColor.r) : (1.0 - 2.0 * (1.0 - desat.r) * (1.0 - filterColor.r))),
                                 (desat.g < 0.5 ? (2.0 * desat.g * filterColor.g) : (1.0 - 2.0 * (1.0 - desat.g) * (1.0 - filterColor.g))),
                                 (desat.b < 0.5 ? (2.0 * desat.b * filterColor.b) : (1.0 - 2.0 * (1.0 - desat.b) * (1.0 - filterColor.b))),
                                 1.0
                                 );
    
    //which is better, or are they equal?
    gl_FragColor = vec4( mix(textureColor.rgb, outputColor.rgb, intensity), textureColor.a);
}
"""
public let MotionBlurVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform vec2 directionalTexelStep;

varying vec2 textureCoordinate;
varying vec2 oneStepBackTextureCoordinate;
varying vec2 twoStepsBackTextureCoordinate;
varying vec2 threeStepsBackTextureCoordinate;
varying vec2 fourStepsBackTextureCoordinate;
varying vec2 oneStepForwardTextureCoordinate;
varying vec2 twoStepsForwardTextureCoordinate;
varying vec2 threeStepsForwardTextureCoordinate;
varying vec2 fourStepsForwardTextureCoordinate;

void main()
{
    gl_Position = position;
    
    textureCoordinate = inputTextureCoordinate.xy;
    oneStepBackTextureCoordinate = inputTextureCoordinate.xy - directionalTexelStep;
    twoStepsBackTextureCoordinate = inputTextureCoordinate.xy - 2.0 * directionalTexelStep;
    threeStepsBackTextureCoordinate = inputTextureCoordinate.xy - 3.0 * directionalTexelStep;
    fourStepsBackTextureCoordinate = inputTextureCoordinate.xy - 4.0 * directionalTexelStep;
    oneStepForwardTextureCoordinate = inputTextureCoordinate.xy + directionalTexelStep;
    twoStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 2.0 * directionalTexelStep;
    threeStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 3.0 * directionalTexelStep;
    fourStepsForwardTextureCoordinate = inputTextureCoordinate.xy + 4.0 * directionalTexelStep;
}
"""
public let MotionBlurFragmentShader = """
uniform sampler2D inputImageTexture;

varying vec2 textureCoordinate;
varying vec2 oneStepBackTextureCoordinate;
varying vec2 twoStepsBackTextureCoordinate;
varying vec2 threeStepsBackTextureCoordinate;
varying vec2 fourStepsBackTextureCoordinate;
varying vec2 oneStepForwardTextureCoordinate;
varying vec2 twoStepsForwardTextureCoordinate;
varying vec2 threeStepsForwardTextureCoordinate;
varying vec2 fourStepsForwardTextureCoordinate;

void main()
{
    vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
    fragmentColor += texture2D(inputImageTexture, oneStepBackTextureCoordinate) * 0.15;
    fragmentColor += texture2D(inputImageTexture, twoStepsBackTextureCoordinate) *  0.12;
    fragmentColor += texture2D(inputImageTexture, threeStepsBackTextureCoordinate) * 0.09;
    fragmentColor += texture2D(inputImageTexture, fourStepsBackTextureCoordinate) * 0.05;
    fragmentColor += texture2D(inputImageTexture, oneStepForwardTextureCoordinate) * 0.15;
    fragmentColor += texture2D(inputImageTexture, twoStepsForwardTextureCoordinate) *  0.12;
    fragmentColor += texture2D(inputImageTexture, threeStepsForwardTextureCoordinate) * 0.09;
    fragmentColor += texture2D(inputImageTexture, fourStepsForwardTextureCoordinate) * 0.05;
    
    gl_FragColor = fragmentColor;
}
"""
public let MotionComparisonFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float intensity;

void main()
{
    vec3 currentImageColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec3 lowPassImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    
    float colorDistance = distance(currentImageColor, lowPassImageColor); // * 0.57735
    float movementThreshold = step(0.2, colorDistance);
    
    gl_FragColor = movementThreshold * vec4(textureCoordinate2.x, textureCoordinate2.y, 1.0, 1.0);
}
"""
public let MultiplyBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlayer = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
}
"""
public let NearbyTexelSamplingVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform float texelWidth;
uniform float texelHeight; 

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

void main()
{
    gl_Position = position;
    
    vec2 widthStep = vec2(texelWidth, 0.0);
    vec2 heightStep = vec2(0.0, texelHeight);
    vec2 widthHeightStep = vec2(texelWidth, texelHeight);
    vec2 widthNegativeHeightStep = vec2(texelWidth, -texelHeight);
    
    textureCoordinate = inputTextureCoordinate.xy;
    leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
    rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
    
    topTextureCoordinate = inputTextureCoordinate.xy - heightStep;
    topLeftTextureCoordinate = inputTextureCoordinate.xy - widthHeightStep;
    topRightTextureCoordinate = inputTextureCoordinate.xy + widthNegativeHeightStep;
    
    bottomTextureCoordinate = inputTextureCoordinate.xy + heightStep;
    bottomLeftTextureCoordinate = inputTextureCoordinate.xy - widthNegativeHeightStep;
    bottomRightTextureCoordinate = inputTextureCoordinate.xy + widthHeightStep;
}
"""
public let NobleCornerDetectorFragmentShader = """
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform float sensitivity;
 
 void main()
 {
     vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
     
     float derivativeSum = derivativeElements.x + derivativeElements.y;
     
     // R = (Ix^2 * Iy^2 - Ixy * Ixy) / (Ix^2 + Iy^2)
     float zElement = (derivativeElements.z * 2.0) - 1.0;
     //     mediump float harrisIntensity = (derivativeElements.x * derivativeElements.y - (derivativeElements.z * derivativeElements.z)) / (derivativeSum);
     float cornerness = (derivativeElements.x * derivativeElements.y - (zElement * zElement)) / (derivativeSum);
     
     // Original Harris detector
     // R = Ix^2 * Iy^2 - Ixy * Ixy - k * (Ix^2 + Iy^2)^2
     //     highp float harrisIntensity = derivativeElements.x * derivativeElements.y - (derivativeElements.z * derivativeElements.z) - harrisConstant * derivativeSum * derivativeSum;
     
     //     gl_FragColor = vec4(vec3(harrisIntensity * 7.0), 1.0);
     gl_FragColor = vec4(vec3(cornerness * sensitivity), 1.0);
 }
"""
public let NormalBlendFragmentShader = """
/*
 This equation is a simplification of the general blending equation. It assumes the destination color is opaque, and therefore drops the destination color's alpha term.
 
 D = C1 * C1a + C2 * C2a * (1 - C1a)
 where D is the resultant color, C1 is the color of the first element, C1a is the alpha of the first element, C2 is the second element color, C2a is the alpha of the second element. The destination alpha is calculated with:
 
 Da = C1a + C2a * (1 - C1a)
 The resultant color is premultiplied with the alpha. To restore the color to the unmultiplied values, just divide by Da, the resultant alpha.
 
 http://stackoverflow.com/questions/1724946/blend-mode-on-a-transparent-and-semi-transparent-background
 
 For some reason Photoshop behaves 
 D = C1 + C2 * C2a * (1 - C1a)
 */

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 c2 = texture2D(inputImageTexture, textureCoordinate);
    vec4 c1 = texture2D(inputImageTexture2, textureCoordinate2);
    
    vec4 outputColor;
    
    //     outputColor.r = c1.r + c2.r * c2.a * (1.0 - c1.a);
    //     outputColor.g = c1.g + c2.g * c2.a * (1.0 - c1.a);
    //     outputColor.b = c1.b + c2.b * c2.a * (1.0 - c1.a);
    //     outputColor.a = c1.a + c2.a * (1.0 - c1.a);
    
    float a = c1.a + c2.a * (1.0 - c1.a);
    float alphaDivisor = a + step(a, 0.0); // Protect against a divide-by-zero blacking out things in the output

    outputColor.r = (c1.r * c1.a + c2.r * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.g = (c1.g * c1.a + c2.g * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.b = (c1.b * c1.a + c2.b * c2.a * (1.0 - c1.a))/alphaDivisor;
    outputColor.a = a;
    
    gl_FragColor = outputColor;
}
"""
public let OneInputVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

varying vec2 textureCoordinate;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
}

"""
public let OpacityFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float opacity;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.rgb, textureColor.a * opacity);
}
"""
public let OverlayBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
    
    float ra;
    if (2.0 * base.r < base.a) {
        ra = 2.0 * overlay.r * base.r + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    } else {
        ra = overlay.a * base.a - 2.0 * (base.a - base.r) * (overlay.a - overlay.r) + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
    }
    
    float ga;
    if (2.0 * base.g < base.a) {
        ga = 2.0 * overlay.g * base.g + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    } else {
        ga = overlay.a * base.a - 2.0 * (base.a - base.g) * (overlay.a - overlay.g) + overlay.g * (1.0 - base.a) + base.g * (1.0 - overlay.a);
    }
    
    float ba;
    if (2.0 * base.b < base.a) {
        ba = 2.0 * overlay.b * base.b + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    } else {
        ba = overlay.a * base.a - 2.0 * (base.a - base.b) * (overlay.a - overlay.b) + overlay.b * (1.0 - base.a) + base.b * (1.0 - overlay.a);
    }
    
    gl_FragColor = vec4(ra, ga, ba, 1.0);
}
"""
public let PassthroughFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
"""
public let PinchDistortionFragmentShader = """
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
"""
public let PixellateFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float fractionalWidthOfPixel;
uniform float aspectRatio;

void main()
{
    vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
    
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
    gl_FragColor = texture2D(inputImageTexture, samplePos );
}
"""
public let PolarPixellateFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 center;
uniform vec2 pixelSize;


void main()
{
    vec2 normCoord = 2.0 * textureCoordinate - 1.0;
    vec2 normCenter = 2.0 * center - 1.0;
    
    normCoord -= normCenter;
    
    float r = length(normCoord); // to polar coords
    float phi = atan(normCoord.y, normCoord.x); // to polar coords
    
    r = r - mod(r, pixelSize.x) + 0.03;
    phi = phi - mod(phi, pixelSize.y);
    
    normCoord.x = r * cos(phi);
    normCoord.y = r * sin(phi);
    
    normCoord += normCenter;
    
    vec2 textureCoordinateToUse = normCoord / 2.0 + 0.5;
    
    gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
    
}
"""
public let PolkaDotFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform float fractionalWidthOfPixel;
uniform float aspectRatio;
uniform float dotScaling;

void main()
{
    vec2 sampleDivisor = vec2(fractionalWidthOfPixel, fractionalWidthOfPixel / aspectRatio);
    
    vec2 samplePos = textureCoordinate - mod(textureCoordinate, sampleDivisor) + 0.5 * sampleDivisor;
    vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    vec2 adjustedSamplePos = vec2(samplePos.x, (samplePos.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    float distanceFromSamplePoint = distance(adjustedSamplePos, textureCoordinateToUse);
    float checkForPresenceWithinDot = step(distanceFromSamplePoint, (fractionalWidthOfPixel * 0.5) * dotScaling);
    
    vec4 inputColor = texture2D(inputImageTexture, samplePos);

    gl_FragColor = vec4(inputColor.rgb * checkForPresenceWithinDot, inputColor.a);
}
"""
public let PosterizeFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float colorLevels;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = floor((textureColor * colorLevels) + vec4(0.5)) / colorLevels;
}
"""
public let PrewittEdgeDetectionFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;
uniform float edgeStrength;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - topIntensity - topRightIntensity + bottomLeftIntensity + bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - leftIntensity - topLeftIntensity + bottomRightIntensity + rightIntensity + topRightIntensity;
    
    float mag = length(vec2(h, v)) * edgeStrength;
    
    gl_FragColor = vec4(vec3(mag), 1.0);
}
"""
public let RGBAdjustmentFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float redAdjustment;
uniform float greenAdjustment;
uniform float blueAdjustment;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(textureColor.r * redAdjustment, textureColor.g * greenAdjustment, textureColor.b * blueAdjustment, textureColor.a);
}
"""
public let SaturationBlendFragmentShader = """
// Saturation blend mode based upon pseudo code from the PDF specification.

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

float lum(vec3 c) {
    return dot(c, vec3(0.3, 0.59, 0.11));
}

vec3 clipcolor(vec3 c) {
    float l = lum(c);
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    
    if (n < 0.0) {
        c.r = l + ((c.r - l) * l) / (l - n);
        c.g = l + ((c.g - l) * l) / (l - n);
        c.b = l + ((c.b - l) * l) / (l - n);
    }
    if (x > 1.0) {
        c.r = l + ((c.r - l) * (1.0 - l)) / (x - l);
        c.g = l + ((c.g - l) * (1.0 - l)) / (x - l);
        c.b = l + ((c.b - l) * (1.0 - l)) / (x - l);
    }
    
    return c;
}

vec3 setlum(vec3 c, float l) {
    float d = l - lum(c);
    c = c + vec3(d);
    return clipcolor(c);
}

float sat(vec3 c) {
    float n = min(min(c.r, c.g), c.b);
    float x = max(max(c.r, c.g), c.b);
    return x - n;
}

float mid(float cmin, float cmid, float cmax, float s) {
    return ((cmid - cmin) * s) / (cmax - cmin);
}

vec3 setsat(vec3 c, float s) {
    if (c.r > c.g) {
        if (c.r > c.b) {
            if (c.g > c.b) {
                /* g is mid, b is min */
                c.g = mid(c.b, c.g, c.r, s);
                c.b = 0.0;
            } else {
                /* b is mid, g is min */
                c.b = mid(c.g, c.b, c.r, s);
                c.g = 0.0;
            }
            c.r = s;
        } else {
            /* b is max, r is mid, g is min */
            c.r = mid(c.g, c.r, c.b, s);
            c.b = s;
            c.r = 0.0;
        }
    } else if (c.r > c.b) {
        /* g is max, r is mid, b is min */
        c.r = mid(c.b, c.r, c.g, s);
        c.g = s;
        c.b = 0.0;
    } else if (c.g > c.b) {
        /* g is max, b is mid, r is min */
        c.b = mid(c.r, c.b, c.g, s);
        c.g = s;
        c.r = 0.0;
    } else if (c.b > c.g) {
        /* b is max, g is mid, r is min */
        c.g = mid(c.r, c.g, c.b, s);
        c.b = s;
        c.r = 0.0;
    } else {
        c = vec3(0.0);
    }
    return c;
}

void main()
{
 vec4 baseColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 overlayColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    gl_FragColor = vec4(baseColor.rgb * (1.0 - overlayColor.a) + setlum(setsat(baseColor.rgb, sat(overlayColor.rgb)), lum(baseColor.rgb)) * overlayColor.a, baseColor.a);
}
"""
public let SaturationFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float saturation;

// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);
    
    gl_FragColor = vec4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
 
}

"""
public let ScreenBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
    vec4 whiteColor = vec4(1.0);
    gl_FragColor = whiteColor - ((whiteColor - textureColor2) * (whiteColor - textureColor));
}
"""
public let SharpenVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;

uniform float texelWidth; 
uniform float texelHeight; 
uniform float sharpness;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate; 
varying vec2 topTextureCoordinate;
varying vec2 bottomTextureCoordinate;

varying float centerMultiplier;
varying float edgeMultiplier;

void main()
{
    gl_Position = position;
    
    vec2 widthStep = vec2(texelWidth, 0.0);
    vec2 heightStep = vec2(0.0, texelHeight);
    
    textureCoordinate = inputTextureCoordinate.xy;
    leftTextureCoordinate = inputTextureCoordinate.xy - widthStep;
    rightTextureCoordinate = inputTextureCoordinate.xy + widthStep;
    topTextureCoordinate = inputTextureCoordinate.xy + heightStep;     
    bottomTextureCoordinate = inputTextureCoordinate.xy - heightStep;
    
    centerMultiplier = 1.0 + 4.0 * sharpness;
    edgeMultiplier = sharpness;
}
"""
public let SharpenFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;
varying vec2 topTextureCoordinate;
varying vec2 bottomTextureCoordinate;

varying float centerMultiplier;
varying float edgeMultiplier;

uniform sampler2D inputImageTexture;

void main()
{
    vec3 textureColor = texture2D(inputImageTexture, textureCoordinate).rgb;
    vec3 leftTextureColor = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
    vec3 rightTextureColor = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
    vec3 topTextureColor = texture2D(inputImageTexture, topTextureCoordinate).rgb;
    vec3 bottomTextureColor = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
    
    gl_FragColor = vec4((textureColor * centerMultiplier - (leftTextureColor * edgeMultiplier + rightTextureColor * edgeMultiplier + topTextureColor * edgeMultiplier + bottomTextureColor * edgeMultiplier)), texture2D(inputImageTexture, bottomTextureCoordinate).w);
}
"""
public let ShiTomasiFeatureDetectorFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float sensitivity;

void main()
{
    vec3 derivativeElements = texture2D(inputImageTexture, textureCoordinate).rgb;
    
    float derivativeDifference = derivativeElements.x - derivativeElements.y;
    float zElement = (derivativeElements.z * 2.0) - 1.0;
    
    // R = Ix^2 + Iy^2 - sqrt( (Ix^2 - Iy^2)^2 + 4 * Ixy * Ixy)
    float cornerness = derivativeElements.x + derivativeElements.y - sqrt(derivativeDifference * derivativeDifference + 4.0 * zElement * zElement);
    
    gl_FragColor = vec4(vec3(cornerness * sensitivity), 1.0);
}
"""
public let SketchFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform float edgeStrength;

uniform sampler2D inputImageTexture;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
    float mag = 1.0 - (length(vec2(h, v)) * edgeStrength);
    
    gl_FragColor = vec4(vec3(mag), 1.0);
}
"""
public let SobelEdgeDetectionFragmentShader = """
//   Code from "Graphics Shaders: Theory and Practice" by M. Bailey and S. Cunningham 

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;
uniform float edgeStrength;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
    float mag = length(vec2(h, v)) * edgeStrength;
    
    gl_FragColor = vec4(vec3(mag), 1.0);
}
"""
public let SoftLightBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 base = texture2D(inputImageTexture, textureCoordinate);
    vec4 overlay = texture2D(inputImageTexture2, textureCoordinate2);
    
    float alphaDivisor = base.a + step(base.a, 0.0); // Protect against a divide-by-zero blacking out things in the output
    gl_FragColor = base * (overlay.a * (base / alphaDivisor) + (2.0 * overlay * (1.0 - (base / alphaDivisor)))) + overlay * (1.0 - base.a) + base * (1.0 - overlay.a);
}
"""
public let SolarizeFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float threshold;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    float luminance = dot(textureColor.rgb, W);
    float thresholdResult = step(luminance, threshold);
    vec3 finalColor = abs(thresholdResult - textureColor.rgb);

    gl_FragColor = vec4(vec3(finalColor), textureColor.w);
}
"""
public let SourceOverBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
    
    gl_FragColor = mix(textureColor, textureColor2, textureColor2.a);
}
"""
public let SphereRefractionFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 center;
uniform float radius;
uniform float aspectRatio;
uniform float refractiveIndex;

void main()
{
    vec2 textureCoordinateToUse = vec2(textureCoordinate.x, (textureCoordinate.y * aspectRatio + 0.5 - 0.5 * aspectRatio));
    float distanceFromCenter = distance(center, textureCoordinateToUse);
    float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
    
    distanceFromCenter = distanceFromCenter / radius;
    
    float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
    vec3 sphereNormal = normalize(vec3(textureCoordinateToUse - center, normalizedDepth));
    
    vec3 refractedVector = refract(vec3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
    
    gl_FragColor = texture2D(inputImageTexture, (refractedVector.xy + 1.0) * 0.5) * checkForPresenceWithinSphere;
}
"""
public let StretchDistortionFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 center;

void main()
{
    vec2 normCoord = 2.0 * textureCoordinate - 1.0;
    vec2 normCenter = 2.0 * center - 1.0;
    
    normCoord -= normCenter;
    vec2 s = sign(normCoord);
    normCoord = abs(normCoord);
    normCoord = 0.5 * normCoord + 0.5 * smoothstep(0.25, 0.5, normCoord) * normCoord;
    normCoord = s * normCoord;
    
    normCoord += normCenter;
    
    vec2 textureCoordinateToUse = normCoord / 2.0 + 0.5;
    
    gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse);
}
"""
public let SubtractBlendFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
 vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
 vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
 
 gl_FragColor = vec4(textureColor.rgb - textureColor2.rgb, textureColor.a);
}
"""
public let SwirlFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 center;
uniform float radius;
uniform float angle;

void main()
{
    vec2 textureCoordinateToUse = textureCoordinate;
    float dist = distance(center, textureCoordinate);
    if (dist < radius)
    {
        textureCoordinateToUse -= center;
        float percent = (radius - dist) / radius;
        float theta = percent * percent * angle * 8.0;
        float s = sin(theta);
        float c = cos(theta);
        textureCoordinateToUse = vec2(dot(textureCoordinateToUse, vec2(c, -s)), dot(textureCoordinateToUse, vec2(s, c)));
        textureCoordinateToUse += center;
    }
    
    gl_FragColor = texture2D(inputImageTexture, textureCoordinateToUse );
}
"""
public let ThreeInputVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;
attribute vec4 inputTextureCoordinate3;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;
varying vec2 textureCoordinate3;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    textureCoordinate2 = inputTextureCoordinate2.xy;
    textureCoordinate3 = inputTextureCoordinate3.xy;
}
"""
public let ThresholdEdgeDetectionFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;
uniform float threshold;

uniform float edgeStrength;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    h = max(0.0, h);
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    v = max(0.0, v);
    
    float mag = length(vec2(h, v)) * edgeStrength;
    mag = step(threshold, mag);
    
    gl_FragColor = vec4(vec3(mag), 1.0);
}
"""
public let ThresholdSketchFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;
uniform float threshold;

uniform float edgeStrength;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    h = max(0.0, h);
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    v = max(0.0, v);
    
    float mag = length(vec2(h, v)) * edgeStrength;
    mag = 1.0 - step(threshold, mag);
    
    gl_FragColor = vec4(vec3(mag), 1.0);
}
"""
public let ThresholdedNonMaximumSuppressionFragmentShader = """
uniform sampler2D inputImageTexture;

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform float threshold;

void main()
{
    float bottomColor = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float bottomLeftColor = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float bottomRightColor = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    vec4 centerColor = texture2D(inputImageTexture, textureCoordinate);
    float leftColor = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightColor = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float topColor = texture2D(inputImageTexture, topTextureCoordinate).r;
    float topRightColor = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftColor = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    
    // Use a tiebreaker for pixels to the left and immediately above this one
    float multiplier = 1.0 - step(centerColor.r, topColor);
    multiplier = multiplier * (1.0 - step(centerColor.r, topLeftColor));
    multiplier = multiplier * (1.0 - step(centerColor.r, leftColor));
    multiplier = multiplier * (1.0 - step(centerColor.r, bottomLeftColor));
    
    float maxValue = max(centerColor.r, bottomColor);
    maxValue = max(maxValue, bottomRightColor);
    maxValue = max(maxValue, rightColor);
    maxValue = max(maxValue, topRightColor);
    
    float finalValue = centerColor.r * step(maxValue, centerColor.r) * multiplier;
    finalValue = step(threshold, finalValue);
    
    gl_FragColor = vec4(finalValue, finalValue, finalValue, 1.0);
    //
    //     gl_FragColor = vec4((centerColor.rgb * step(maxValue, step(threshold, centerColor.r)) * multiplier), 1.0);
}
"""
public let TiltShiftFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float topFocusLevel;
uniform float bottomFocusLevel;
uniform float focusFallOffRate;

void main()
{
    vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
    vec4 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2);
    
    float blurIntensity = 1.0 - smoothstep(topFocusLevel - focusFallOffRate, topFocusLevel, textureCoordinate2.y);
    blurIntensity += smoothstep(bottomFocusLevel, bottomFocusLevel + focusFallOffRate, textureCoordinate2.y);
    
    gl_FragColor = mix(sharpImageColor, blurredImageColor, blurIntensity);
}
"""
public let ToonFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

uniform float intensity;
uniform float threshold;
uniform float quantizationLevels;

const vec3 W = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float h = -topLeftIntensity - 2.0 * topIntensity - topRightIntensity + bottomLeftIntensity + 2.0 * bottomIntensity + bottomRightIntensity;
    float v = -bottomLeftIntensity - 2.0 * leftIntensity - topLeftIntensity + bottomRightIntensity + 2.0 * rightIntensity + topRightIntensity;
    
    float mag = length(vec2(h, v));
    
    vec3 posterizedImageColor = floor((textureColor.rgb * quantizationLevels) + 0.5) / quantizationLevels;
    
    float thresholdTest = 1.0 - step(threshold, mag);
    
    gl_FragColor = vec4(posterizedImageColor * thresholdTest, textureColor.a);
}
"""
public let TransformVertexShader = """
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
"""
public let TwoInputVertexShader = """
attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec4 inputTextureCoordinate2;

varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    textureCoordinate2 = inputTextureCoordinate2.xy;
}

"""
public let UnsharpMaskFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform float intensity;

void main()
{
    vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);
    vec3 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;
    
    gl_FragColor = vec4(sharpImageColor.rgb * intensity + blurredImageColor * (1.0 - intensity), sharpImageColor.a);
}
"""
public let VibranceFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform float vibrance;

void main() {
    vec4 color = texture2D(inputImageTexture, textureCoordinate);
    float average = (color.r + color.g + color.b) / 3.0;
    float mx = max(color.r, max(color.g, color.b));
    float amt = (mx - average) * (-vibrance * 3.0);
    color.rgb = mix(color.rgb, vec3(mx), amt);
    gl_FragColor = color;
}
"""
public let VignetteFragmentShader = """
uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

uniform vec2 vignetteCenter;
uniform vec3 vignetteColor;
uniform float vignetteStart;
uniform float vignetteEnd;

void main()
{
    vec4 sourceImageColor = texture2D(inputImageTexture, textureCoordinate);
    float d = distance(textureCoordinate, vec2(vignetteCenter.x, vignetteCenter.y));
    float percent = smoothstep(vignetteStart, vignetteEnd, d);
    gl_FragColor = vec4(mix(sourceImageColor.rgb, vignetteColor, percent), sourceImageColor.a);
}
"""
public let WeakPixelInclusionFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float centerIntensity = texture2D(inputImageTexture, textureCoordinate).r;
    
    float pixelIntensitySum = bottomLeftIntensity + topRightIntensity + topLeftIntensity + bottomRightIntensity + leftIntensity + rightIntensity + bottomIntensity + topIntensity + centerIntensity;
    float sumTest = step(1.5, pixelIntensitySum);
    float pixelTest = step(0.01, centerIntensity);
    
    gl_FragColor = vec4(vec3(sumTest * pixelTest), 1.0);
}
"""
public let WhiteBalanceFragmentShader = """
uniform sampler2D inputImageTexture;
varying vec2 textureCoordinate;

uniform float temperature;
uniform float tint;

const vec3 warmFilter = vec3(0.93, 0.54, 0.0);

const mat3 RGBtoYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311);
const mat3 YIQtoRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702);

void main()
{
    vec4 source = texture2D(inputImageTexture, textureCoordinate);

    vec3 yiq = RGBtoYIQ * source.rgb; //adjusting tint
    yiq.b = clamp(yiq.b + tint*0.5226*0.1, -0.5226, 0.5226);
    vec3 rgb = YIQtoRGB * yiq;
   
    vec3 processed = vec3(
                          (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting temperature
                          (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))),
                          (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));
   
     gl_FragColor = vec4(mix(rgb, processed, temperature), source.a);
}
"""
public let XYDerivativeFragmentShader = """
// I'm using the Prewitt operator to obtain the derivative, then squaring the X and Y components and placing the product of the two in Z.
// In tests, Prewitt seemed to be tied with Sobel for the best, and it's just a little cheaper to compute.
// This is primarily intended to be used with corner detection filters.

varying vec2 textureCoordinate;
varying vec2 leftTextureCoordinate;
varying vec2 rightTextureCoordinate;

varying vec2 topTextureCoordinate;
varying vec2 topLeftTextureCoordinate;
varying vec2 topRightTextureCoordinate;

varying vec2 bottomTextureCoordinate;
varying vec2 bottomLeftTextureCoordinate;
varying vec2 bottomRightTextureCoordinate;

uniform sampler2D inputImageTexture;

void main()
{
    float topIntensity = texture2D(inputImageTexture, topTextureCoordinate).r;
    float topRightIntensity = texture2D(inputImageTexture, topRightTextureCoordinate).r;
    float topLeftIntensity = texture2D(inputImageTexture, topLeftTextureCoordinate).r;
    float bottomIntensity = texture2D(inputImageTexture, bottomTextureCoordinate).r;
    float bottomLeftIntensity = texture2D(inputImageTexture, bottomLeftTextureCoordinate).r;
    float bottomRightIntensity = texture2D(inputImageTexture, bottomRightTextureCoordinate).r;
    float leftIntensity = texture2D(inputImageTexture, leftTextureCoordinate).r;
    float rightIntensity = texture2D(inputImageTexture, rightTextureCoordinate).r;
    
    float verticalDerivative = -topLeftIntensity - topIntensity - topRightIntensity + bottomLeftIntensity + bottomIntensity + bottomRightIntensity;
    float horizontalDerivative = -bottomLeftIntensity - leftIntensity - topLeftIntensity + bottomRightIntensity + rightIntensity + topRightIntensity;
    verticalDerivative = verticalDerivative;
    horizontalDerivative = horizontalDerivative;
    
    // Scaling the X * Y operation so that negative numbers are not clipped in the 0..1 range. This will be expanded in the corner detection filter
    gl_FragColor = vec4(horizontalDerivative * horizontalDerivative, verticalDerivative * verticalDerivative, ((verticalDerivative * horizontalDerivative) + 1.0) / 2.0, 1.0);
}
"""
public let YUVConversionFullRangeUVPlanarFragmentShader = """
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

"""
public let YUVConversionFullRangeFragmentShader = """
varying vec2 textureCoordinate;
varying vec2 textureCoordinate2;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

uniform mat3 colorConversionMatrix;

void main()
{
    vec3 yuv;
    
    yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
    yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
    vec3 rgb = colorConversionMatrix * yuv;
    
    gl_FragColor = vec4(rgb, 1.0);
}

"""
public let YUVConversionVideoRangeFragmentShader = """
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
"""
public let ZoomBlurFragmentShader = """
varying vec2 textureCoordinate;

uniform sampler2D inputImageTexture;

uniform vec2 blurCenter;
uniform float blurSize;

void main()
{
    // TODO: Do a more intelligent scaling based on resolution here
    vec2 samplingOffset = 1.0/100.0 * (blurCenter - textureCoordinate) * blurSize;
    
    vec4 fragmentColor = texture2D(inputImageTexture, textureCoordinate) * 0.18;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + samplingOffset) * 0.15;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + (2.0 * samplingOffset)) *  0.12;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + (3.0 * samplingOffset)) * 0.09;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate + (4.0 * samplingOffset)) * 0.05;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - samplingOffset) * 0.15;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - (2.0 * samplingOffset)) *  0.12;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - (3.0 * samplingOffset)) * 0.09;
    fragmentColor += texture2D(inputImageTexture, textureCoordinate - (4.0 * samplingOffset)) * 0.05;
    
    gl_FragColor = fragmentColor;
}
"""
