#version 440

layout(location = 0) in vec2 v_TexCoord;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float bgAlpha;
    float lumaLow;
    float lumaHigh;
};

void main()
{
    vec4 c = texture(source, v_TexCoord);
    float luma = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    float a = mix(bgAlpha, 1.0, smoothstep(lumaLow, lumaHigh, luma));
    fragColor = vec4(c.rgb * a, a) * qt_Opacity;
}
