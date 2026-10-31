#version 440

layout(location = 0) in vec2 v_TexCoord;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D backTex;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 bar;
    float barRadius;
    vec4 bud0;
    vec4 bud1;
    vec4 bud2;
    vec4 bud3;
    vec2 backgroundSize;
    vec2 screenOrigin;
    vec2 halfpixel;
    float thickness;
    float refractionWidth;
    float rgbDriftStrength;
    float highlightWidth;
    float highlightStrength;
    float saturation;
    float centerOpacity;
};

float sdRoundBox(vec2 p, vec2 halfSize, float r)
{
    vec2 q = abs(p) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float sdCircle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

float smoothUnion(float a, float b, float k)
{
    if (k <= 0.001) {
        return min(a, b);
    }
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float budField(float d, vec2 p, vec4 bud)
{
    if (bud.z <= 0.01) {
        return d;
    }
    return smoothUnion(d, sdCircle(p, bud.xy, bud.z), bud.w);
}

float field(vec2 p)
{
    vec2 halfSize = bar.zw * 0.5;
    float d = sdRoundBox(p - (bar.xy + halfSize), halfSize, min(barRadius, min(halfSize.x, halfSize.y)));
    d = budField(d, p, bud0);
    d = budField(d, p, bud1);
    d = budField(d, p, bud2);
    d = budField(d, p, bud3);
    return d;
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
    vec2 p = v_TexCoord * itemSize;
    float d = field(p);
    float mask = clamp(0.5 - d, 0.0, 1.0);
    if (mask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 grad = vec2(field(p + vec2(1.0, 0.0)) - field(p - vec2(1.0, 0.0)),
                     field(p + vec2(0.0, 1.0)) - field(p - vec2(0.0, 1.0)));
    vec2 outNorm = length(grad) > 0.0001 ? normalize(grad) : vec2(0.0, -1.0);
    float inside = max(-d, 0.0);

    float refrBand = max(refractionWidth * 1.25, 1.0);
    float edgeT = smoothstep(-refrBand, 0.0, d);
    float edgeQ = edgeT * edgeT;

    vec2 uv = (screenOrigin + p) / backgroundSize;
    vec2 lensUV = clamp(uv - outNorm * thickness * edgeQ / max(backgroundSize, vec2(1.0)), 0.0, 1.0);

    vec3 col = lgGaussianBlur(backTex, halfpixel * 2.0, lensUV);
    col = lgApplyRgbDrift(backTex, col, lensUV, outNorm, backgroundSize, rgbDriftStrength, edgeQ);
    col = lgApplyHighlight(col, inside, outNorm, highlightWidth, highlightStrength);

    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, saturation);

    float coverage = mix(centerOpacity, 1.0, edgeQ);
    fragColor = vec4(col, 1.0) * (mask * qt_Opacity * coverage);
}
