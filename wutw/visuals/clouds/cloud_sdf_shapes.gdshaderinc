#include "res://visuals/shaders/sdf.gdshaderinc"

group_uniforms cloud_smoothness;
uniform float cloud_merge_k : hint_range(0.001, 0.1, 0.001) = 0.004;

group_uniforms cloud_distortion;
uniform float distortion_amplitude : hint_range(0.0001, 0.1) = 0.01;
uniform float distortion_speed : hint_range(0.001, 10) = 1.0;

float sdf_cloud_piece(vec2 p, vec2 position, vec2 size, float random_seed) {
	size *= 1.0 + 10.0*(1.0 + sin(random_seed * TAU + TIME * distortion_speed)) * distortion_amplitude;
	return sdf_ellipse(translate(p, position), size);
}

#define DRAW_ELLIPSE(x, y, sx, sy) \
	dist = smooth_union(dist, sdf_cloud_piece(p, vec2(x, y), vec2(sx, sy), variation_random + float(i++) * 0.6543231), cloud_merge_k);

float sdf_cloud_1(vec2 p) {
	float dist = 1.0;
	int i = 0;
	DRAW_ELLIPSE(-0.275, 0.115, 0.085, 0.025);
	DRAW_ELLIPSE(0.14, 0.0, 0.075, 0.075);
	DRAW_ELLIPSE(0.12, 0.095, 0.08, 0.06);
	DRAW_ELLIPSE(0.23, 0.07, 0.095, 0.07);
	DRAW_ELLIPSE(-0.037, 0.12, 0.105, 0.045);
	DRAW_ELLIPSE(-0.015, -0.04, 0.145, 0.15);
	DRAW_ELLIPSE(-0.14, 0.075, 0.08, 0.07);
	DRAW_ELLIPSE(-0.225, 0.065, 0.065, 0.035);
	return dist;
}

float sdf_cloud_2(vec2 p) {
	float dist = 1.0;
	int i = 0;
	DRAW_ELLIPSE(-0.27, 0.095, 0.11, 0.035);
	DRAW_ELLIPSE(-0.06, 0.115, 0.105, 0.055);
	DRAW_ELLIPSE(-0.04, -0.085, 0.105, 0.09);
	DRAW_ELLIPSE(0.14, -0.01, 0.095, 0.08);
	DRAW_ELLIPSE(0.123, 0.11, 0.105, 0.045);
	DRAW_ELLIPSE(-0.19, 0.025, 0.07, 0.055);
	DRAW_ELLIPSE(0.265, 0.075, 0.1, 0.045);
	DRAW_ELLIPSE(-0.025, 0.02, 0.125, 0.095);
	return dist;
}

float sdf_cloud_3(vec2 p) {
	float dist = 1.0;
	int i = 0;
	DRAW_ELLIPSE(0.03, -0.02, 0.11, 0.08);
	DRAW_ELLIPSE(-0.145, 0.045, 0.105, 0.07);
	DRAW_ELLIPSE(-0.285, 0.145, 0.1, 0.07);
	DRAW_ELLIPSE(0.265, 0.14, 0.085, 0.06);
	DRAW_ELLIPSE(0.1, 0.05, 0.1, 0.1);
	DRAW_ELLIPSE(-0.175, 0.17, 0.1, 0.065);
	DRAW_ELLIPSE(-0.005, 0.16, 0.145, 0.07);
	DRAW_ELLIPSE(0.145, 0.165, 0.17, 0.07);
	return dist;
}

float sdf_cloud_4(vec2 p) {
	float dist = 1.0;
	int i = 0;
	DRAW_ELLIPSE(0.015, -0.06, 0.14, 0.085);
	DRAW_ELLIPSE(-0.305, 0.07, 0.105, 0.02);
	DRAW_ELLIPSE(-0.205, 0.045, 0.06, 0.04);
	DRAW_ELLIPSE(-0.24, 0.085, 0.09, 0.025);
	DRAW_ELLIPSE(-0.115, 0.005, 0.045, 0.04);
	DRAW_ELLIPSE(0.005, 0.09, 0.205, 0.065);
	DRAW_ELLIPSE(0.26, 0.07, 0.145, 0.035);
	DRAW_ELLIPSE(0.13, 0.02, 0.14, 0.05);
	return dist;
}

float sdf_cloud_5(vec2 p) {
	float dist = 1.0;
	int i = 0;
	DRAW_ELLIPSE(-0.015, -0.09, 0.1, 0.085);
	DRAW_ELLIPSE(0.13, -0.045, 0.085, 0.065);
	DRAW_ELLIPSE(0.25, 0.035, 0.07, 0.05);
	DRAW_ELLIPSE(-0.23, 0.065, 0.09, 0.035);
	DRAW_ELLIPSE(-0.17, 0.005, 0.06, 0.05);
	DRAW_ELLIPSE(-0.01, 0.03, 0.205, 0.065);
	DRAW_ELLIPSE(-0.04, 0.125, 0.12, 0.035);
	DRAW_ELLIPSE(0.12, 0.08, 0.075, 0.03);
	return dist;
}

float sdf_cloud_6(vec2 p) {
	float dist = 1.0;
	int i = 0;
	DRAW_ELLIPSE(0.035, -0.1, 0.1, 0.085);
	DRAW_ELLIPSE(-0.1, -0.06, 0.065, 0.065);
	DRAW_ELLIPSE(-0.21, 0.02, 0.065, 0.05);
	DRAW_ELLIPSE(-0.3, 0.08, 0.09, 0.045);
	DRAW_ELLIPSE(0.165, -0.01, 0.06, 0.05);
	DRAW_ELLIPSE(0.29, 0.08, 0.08, 0.065);
	DRAW_ELLIPSE(0.02, 0.035, 0.195, 0.075);
	DRAW_ELLIPSE(-0.165, 0.11, 0.075, 0.045);
	DRAW_ELLIPSE(-0.01, 0.14, 0.085, 0.035);
	DRAW_ELLIPSE(0.14, 0.105, 0.09, 0.06);
	return dist;
}

float sdf_cloud_varied(vec2 p, float seed) {
	float variation = seed * 6.0;
	if (variation <= 1.0) {
		return sdf_cloud_1(p);
	} else if (variation <= 2.0) {
		return sdf_cloud_2(p);
	} else if (variation <= 3.0) {
		return sdf_cloud_3(p);
	} else if (variation <= 4.0) {
		return sdf_cloud_4(p);
	} else if (variation <= 5.0) {
		return sdf_cloud_5(p);
	} else {
		return sdf_cloud_6(p);
	}
}
