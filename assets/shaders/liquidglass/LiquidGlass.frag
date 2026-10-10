#version 440

layout(location = 0) in vec2 v_TexCoord;
layout(location = 0) out vec4 o_Color;

layout(binding = 1) uniform sampler2D u_Slots5;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 v_MidPoint;
    vec2 v_QuadNDC2ScreenNDCScale;
    vec2 u_size;
    float u_cornerRadius;
    vec2 u_lightDir;
    float u_rimWidth;
    float u_rimStrength;
    float u_sheenWidth;
    float u_sheenStrength;
    float u_powerFactor;
    float u_a;
    float u_b;
    float u_c;
    float u_d;
    float u_fPower;
    float u_noise;
    float u_glowWeight;
    float u_glowBias;
    float u_glowEdge0;
    float u_glowEdge1;
};

float sdSuperellipse(vec2 p, float n, float r) {
    vec2 p_abs = abs(p);

    float numerator = pow(p_abs.x, n) + pow(p_abs.y, n) - pow(r, n);

    float den_x = pow(p_abs.x, 2.0 * n - 2.0);
    float den_y = pow(p_abs.y, 2.0 * n - 2.0);

    float denominator = n * sqrt(den_x + den_y) + 0.00001;

    return numerator / denominator;
}

float sdRoundedBox(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec2 sdRoundedBoxNormal(vec2 p, vec2 b, float r) {
	vec2 s = vec2(p.x < 0.0 ? -1.0 : 1.0, p.y < 0.0 ? -1.0 : 1.0);
	vec2 q = abs(p) - b + r;
	vec2 n;
	if (q.x > 0.0 && q.y > 0.0) {
		n = normalize(q);
	} else if (q.x > q.y) {
		n = vec2(1.0, 0.0);
	} else {
		n = vec2(0.0, 1.0);
	}
	return n * s;
}

const float M_E = 2.718281828459045;
const float M_TAU = 6.28318530718;

float f(float x) {
	return 1.0 - u_b * pow(u_c * M_E, -u_d * x - u_a);
}

float rand(vec2 co){
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float Glow() {
	return sin(atan(v_TexCoord.y * 2 - 1, v_TexCoord.x * 2 - 1) - 0.5);
}

vec4 LiquidGlass() {
	vec2 center = vec2(0.5);
	vec2 p = (v_TexCoord - center) * 2;
	float r = 1;
	float d;
	float coverage = 1.0;
	vec2 halfSize = u_size * 0.5;
	float m = min(halfSize.x, halfSize.y);
	vec2 normalDir = vec2(0.0);
	if (u_cornerRadius < 0.0) {
		d = sdSuperellipse(p, u_powerFactor, r);
		if (d > 0)
			discard;
	} else {
		vec2 pPx = p * halfSize;
		float cr = min(u_cornerRadius, m);
		d = sdRoundedBox(pPx, halfSize, cr) / m;
		coverage = clamp(0.5 - d * m, 0.0, 1.0);
		if (coverage <= 0.0)
			discard;
		normalDir = sdRoundedBoxNormal(pPx, halfSize, cr);
	}

	float dist = -d;
	vec2 sampleP;
	if (u_cornerRadius < 0.0) {
		sampleP = p * pow(f(dist), u_fPower);
	} else {
		float shift = (1.0 - pow(f(dist), u_fPower)) * (1.0 - dist) * m;
		sampleP = p - normalDir * shift / halfSize;
	}

	vec2 targetNDC = sampleP * v_QuadNDC2ScreenNDCScale + v_MidPoint.xy;
	vec2 coord = targetNDC * 0.5 + vec2(0.5);

	if (max(coord.x, coord.y) > 1.0 || min(coord.x, coord.y) < 0.0)
		return vec4(1.0, 0.0, 1.0, 1.0);

	vec4 noise = vec4(vec3(rand(gl_FragCoord.xy * 1e-3) - 0.5), 0.0);

	vec4 color = texture(u_Slots5, vec2(coord.x, 1.0 - coord.y)) + noise * u_noise;
	float mul = Glow() * u_glowWeight * smoothstep(u_glowEdge0, u_glowEdge1, dist) + 1 + u_glowBias;
	vec4 lit = color * vec4(vec3(mul), 1.0);
	if (u_cornerRadius >= 0.0) {
		float inner = max(-d * m, 0.0);
		float lobe = abs(dot(normalDir, normalize(u_lightDir)));
		float angular = 0.45 + 0.55 * lobe;
		float rimW = max(u_rimWidth, 1.0);
		float rim = 1.0 - smoothstep(0.0, rimW, abs(inner - rimW * 0.5));
		float sheenW = max(min(u_sheenWidth, m * 0.6), 1.0);
		float sheen = 1.0 - smoothstep(0.0, sheenW, inner);
		lit.rgb += vec3(rim * u_rimStrength + sheen * sheen * u_sheenStrength) * angular;
	}
	return lit * coverage;
}

void main()
{
	o_Color = LiquidGlass() * qt_Opacity;
}
