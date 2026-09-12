float value_noise_1_1(float seed) {
	return fract(sin(seed * 12.9898) * 43758.5453);
}

float value_noise_2_1(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise_2_1_smooth(vec2 p, float smoothness) {
	vec2 i = floor(p);
	float a = value_noise_2_1(i);
	float b = value_noise_2_1(i + vec2(1.0, 0.0));
	float c = value_noise_2_1(i + vec2(0.0, 1.0));
	float d = value_noise_2_1(i + vec2(1.0, 1.0));
	vec2 u = vec2(smoothness / 2.0);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float brush_noise(vec2 p, float smoothness) {
	return mix(value_noise_2_1_smooth(floor(p), smoothness), value_noise_2_1_smooth(floor(p * 1.678), smoothness), 0.2);
}
