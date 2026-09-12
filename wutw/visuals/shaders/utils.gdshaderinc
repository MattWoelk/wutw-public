float invLerp(float from, float to, float value) {
	return (value - from) / (to - from);
}

float remap(float value, float origFrom, float origTo, float targetFrom, float targetTo) {
	float rel = invLerp(origFrom, origTo, value);
	return mix(targetFrom, targetTo, clamp(rel, 0.0, 1.0));
}

vec2 remap2(vec2 value, vec2 origFrom, vec2 origTo, vec2 targetFrom, vec2 targetTo) {
	return vec2(
		remap(value.x, origFrom.x, origTo.x, targetFrom.x, targetTo.x),
		remap(value.y, origFrom.y, origTo.y, targetFrom.y, targetTo.y)
	);
}

vec2 remap2(vec2 value, float origFrom, float origTo, float targetFrom, float targetTo) {
	return remap2(value, vec2(origFrom), vec2(origTo), vec2(targetFrom), vec2(targetTo));
}

vec2 distort(vec2 uv, float amplitude, float frequency, float time) {
	return uv + vec2(sin(uv.y*frequency+time)/amplitude, cos(uv.x*frequency+time)/amplitude);
}

vec2 distort2(vec2 uv, float amplitude, vec2 frequency, float time) {
	return uv + vec2(sin(uv.y*frequency.x+time)/amplitude, cos(uv.x*frequency.y+time)/amplitude);
}

float mix3(float a, float b, float c, float t) {
	if (t < 0.0) {
		return mix(b, a, -t);
	} else {
		return mix(b, c, t);
	}
}

vec3 mix3(vec3 a, vec3 b, vec3 c, float t) {
	if (t < 0.0) {
		return mix(b, a, -t);
	} else {
		return mix(b, c, t);
	}
}

float min3(float a, float b, float c) {
	return min(b, min(b, c));
}

float max3(float a, float b, float c) {
	return max(a, max(b, c));
}

float darkest(vec3 c) {
	return min3(c.r, c.g, c.b);
}

float lightest(vec3 c) {
	return max3(c.r, c.g, c.b);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 desaturate(vec3 c) {
	vec3 lum = vec3(0.299, 0.587, 0.114);
	vec3 gray = vec3(dot(lum, c));
	return vec3(gray);
}

vec4 alpha_blend(vec4 color_a, vec4 color_b) {
	float out_alpha = color_a.a + color_b.a * (1.0 - color_a.a);
	if (out_alpha < 0.0001) {
		return vec4(0.0, 0.0, 0.0, 0.0);
	}
	vec3 out_rgb = (color_a.rgb * color_a.a + color_b.rgb * color_b.a * (1.0 - color_a.a)) / out_alpha;
	return vec4(out_rgb, out_alpha);
}
