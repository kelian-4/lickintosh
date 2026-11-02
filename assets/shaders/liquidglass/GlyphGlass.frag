#version 440

layout(location = 0) in vec2 v_TexCoord;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D maskTex;
layout(binding = 2) uniform sampler2D backTex;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec2 screenOrigin;
    vec2 backgroundSize;
    float ringRadius;
    float thickness;
    float highlightStrength;
    float highlightWidth;
    float saturation;
    float lift;
};

float coverage(vec2 uv)
{
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
        return 0.0;
    }
    return texture(maskTex, uv).a;
}

void main()
{
    vec2 texel = 1.0 / size;
    float a = coverage(v_TexCoord);
    if (a <= 0.003) {
        fragColor = vec4(0.0);
        return;
    }

    float sum = 0.0;
    float total = 0.0;
    vec2 inward = vec2(0.0);
    for (int ring = 1; ring <= 2; ++ring) {
        float r = ringRadius * (ring == 1 ? 0.5 : 1.0);
        float phase = ring == 2 ? 0.2618 : 0.0;
        for (int i = 0; i < 12; ++i) {
            float ang = 6.2831853 * float(i) / 12.0 + phase;
            vec2 dir = vec2(cos(ang), sin(ang));
            float c = coverage(v_TexCoord + dir * r * texel);
            sum += c;
            total += 1.0;
            inward += dir * c;
        }
    }

    float depth01 = clamp((sum / total - 0.5) * 2.0, 0.0, 1.0);
    float inside = depth01 * ringRadius;
    float len = length(inward);
    vec2 n = len > 0.0001 ? -inward / len : vec2(0.0, -1.0);
    float edgeQ = (1.0 - depth01) * (1.0 - depth01);

    vec2 uv = (screenOrigin + v_TexCoord * size) / backgroundSize;
    vec2 lensUV = clamp(uv - n * thickness * edgeQ / backgroundSize, 0.0, 1.0);
    vec3 col = texture(backTex, lensUV).rgb;

    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(vec3(luma), col, saturation) + lift;

    float rim = exp(-inside * (2.0 / max(highlightWidth, 0.5)));
    float angular = 0.65 + 0.55 * clamp(-n.y * 0.5 + 0.5, 0.0, 1.0);
    col = mix(col, vec3(0.87, 0.93, 1.0), clamp(rim * highlightStrength * angular, 0.0, 0.95));

    fragColor = vec4(col * a, a) * qt_Opacity;
}
