#version 440

layout(location = 0) in vec2 v_TexCoord;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D texUnit;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    mat4 colorMatrix;
    vec4 cornerRadius;
    vec2 blurSize;
    vec2 backgroundSize;
    vec2 screenOrigin;
    vec2 halfpixel;
    float cornerSquircle;
    float rgbDriftStrength;
    float magnifyGlassStrength;
    float refractionWidth;
    float highlightWidth;
    float highlightStrength;
    float materialOpacity;
    float centerOpacity;
};

float lgCornerLength(vec2 q)
{
    float circle = length(q);
    float squircle = pow(dot(q * q, q * q), 0.25);
    return mix(circle, squircle, cornerSquircle);
}

float lgRoundedRectDistance(vec2 p, vec2 halfSize, vec4 cornerRadius)
{
    float r = p.x > 0.0
        ? (p.y > 0.0 ? cornerRadius.y : cornerRadius.w)
        : (p.y > 0.0 ? cornerRadius.x : cornerRadius.z);
    vec2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + lgCornerLength(max(q, 0.0)) - r;
}

float lgRoundedRectCoverage(float distance)
{
    float pixelWidth = max(fwidth(distance), 1.0);
    return 1.0 - smoothstep(-0.5 * pixelWidth, 0.5 * pixelWidth, distance);
}

vec2 lgRoundedRectNormal(vec2 p, vec2 halfSize, vec4 cornerRadius)
{
    float r = p.x > 0.0
        ? (p.y > 0.0 ? cornerRadius.y : cornerRadius.w)
        : (p.y > 0.0 ? cornerRadius.x : cornerRadius.z);
    vec2 q = abs(p) - halfSize + r;
    vec2 qc = max(q, 0.0);
    float ql = length(qc);
    vec2 n = (ql > 0.001)
        ? qc / ql
        : (q.x > q.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
    return n * sign(p + 0.0001);
}

vec3 lgGaussianBlur(sampler2D texUnit, vec2 texel, vec2 uvCenter)
{
    vec3 total = vec3(0.0);
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            float weight = (x == 0 ? 6.0 : 5.0) * (y == 0 ? 6.0 : 5.0);
            vec2 coord = uvCenter + vec2(float(x), float(y)) * texel * 1.2;
            total += texture(texUnit, clamp(coord, 0.0, 1.0)).rgb * weight;
        }
    }
    return total / 256.0;
}

vec2 lgDockLensUV(vec2 uv, vec2 outwardNormal, vec2 surfacePosition, vec2 surfaceSize,
                  vec2 backgroundSize, float strength, float edgeQ)
{
    float thickness = min(surfaceSize.x, surfaceSize.y) * strength * 3.5;
    vec2 local = surfacePosition / max(surfaceSize * 0.5, vec2(1.0));
    vec2 radial = local / max(length(local), 0.001);
    vec2 direction = normalize(mix(outwardNormal, radial, 0.65));
    vec2 textureNormal = direction;
    return clamp(uv - textureNormal * thickness * edgeQ / max(backgroundSize, vec2(1.0)), 0.0, 1.0);
}

vec3 lgApplyRgbDrift(sampler2D texUnit,
                     vec3 baseColor,
                     vec2 lensUV,
                     vec2 outwardNormal,
                     vec2 blurSizePx,
                     float rgbDriftStrength,
                     float edgeQ)
{
    vec2 safeSize = max(blurSizePx, vec2(1.0));
    vec2 drift = outwardNormal * (rgbDriftStrength / safeSize);

    float r = texture(texUnit, clamp(lensUV + drift, 0.0, 1.0)).r;
    float g = texture(texUnit, clamp(lensUV + drift * 0.30, 0.0, 1.0)).g;
    float b = texture(texUnit, clamp(lensUV - drift * 0.25, 0.0, 1.0)).b;

    return mix(baseColor, vec3(r, g, b), edgeQ);
}

float lgRimAngularWeight(vec2 outNorm)
{
    return 0.65 + 0.55 * clamp(-outNorm.y * 0.5 + 0.5, 0.0, 1.0);
}

vec3 lgApplyHighlight(vec3 color, float inside, vec2 outNorm,
                      float highlightWidth, float highlightStrength)
{
    float band = max(highlightWidth, 1.0);
    float rim = 1.6 * exp(-inside * (2.0 / band));
    float intensity = rim * highlightStrength * lgRimAngularWeight(outNorm);
    return mix(color, vec3(0.87, 0.93, 1.0), clamp(intensity, 0.0, 0.95));
}

void main()
{
    vec2 halfSize = blurSize * 0.5;
    vec2 pos = (v_TexCoord - 0.5) * blurSize;
    vec2 uv = (screenOrigin + v_TexCoord * blurSize) / backgroundSize;

    float d = lgRoundedRectDistance(pos, halfSize, cornerRadius);
    float mask = lgRoundedRectCoverage(d);
    if (mask <= 0.0) {
        discard;
    }

    vec2 outNorm = lgRoundedRectNormal(pos, halfSize, cornerRadius);
    float inside = max(-d, 0.0);

    float refrBand = max(refractionWidth * 1.25, 1.0);
    float edgeT = smoothstep(-refrBand, 0.0, d);
    float edgeQ = edgeT * edgeT;

    vec2 lensUV = uv;
    if (magnifyGlassStrength > 0.0) {
        lensUV = lgDockLensUV(uv, outNorm, pos, blurSize, backgroundSize, magnifyGlassStrength, edgeQ);
    }
    vec2 texel = halfpixel * 2.0;
    vec3 col = lgGaussianBlur(texUnit, texel, lensUV);
    if (rgbDriftStrength > 0.0) {
        col = lgApplyRgbDrift(texUnit, col, lensUV, outNorm, backgroundSize, rgbDriftStrength, edgeQ);
    }
    if (highlightStrength > 0.0) {
        col = lgApplyHighlight(col, inside, outNorm, highlightWidth, highlightStrength);
    }

    vec4 surface = vec4(col, 1.0) * colorMatrix;
    float coverage = materialOpacity * mix(centerOpacity, 1.0, edgeQ);
    fragColor = surface * (mask * qt_Opacity * coverage);
}
