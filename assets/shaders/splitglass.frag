#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 bar;
    float barRadius;
    float rimWidth;
    vec2 lightDir;
    vec4 baseColor;
    vec4 rimColor;
    vec4 bud0;
    vec4 bud1;
    vec4 bud2;
    vec4 bud3;
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

void main()
{
    vec2 p = qt_TexCoord0 * itemSize;
    float d = field(p);
    float coverage = clamp(0.5 - d, 0.0, 1.0);

    if (coverage <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 grad = vec2(field(p + vec2(1.0, 0.0)) - field(p - vec2(1.0, 0.0)),
                     field(p + vec2(0.0, 1.0)) - field(p - vec2(0.0, 1.0)));
    vec2 n = length(grad) > 0.0001 ? normalize(grad) : vec2(0.0, -1.0);

    float band = 1.0 - clamp(-d / max(rimWidth, 0.001), 0.0, 1.0);
    float facing = abs(dot(n, normalize(lightDir)));
    float rimAmount = band * band * (0.25 + 0.75 * facing * facing);

    vec4 base = vec4(baseColor.rgb * baseColor.a, baseColor.a);
    vec4 rim = vec4(rimColor.rgb, 1.0) * (rimColor.a * rimAmount);
    vec4 color = base * (1.0 - rim.a) + rim;

    fragColor = color * coverage * qt_Opacity;
}
