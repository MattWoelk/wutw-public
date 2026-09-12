shader_type canvas_item;

uniform sampler2D edge_tex : filter_linear_mipmap;
uniform float base_alpha = 1.1;
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float edge : hint_range(0.0, 0.5, 0.001) = 0.05;
uniform vec2 stroke_range = vec2(0.0, 1.0);
uniform vec2 cap_range = vec2(0.0, 1.0);

#include "res://visuals/shaders/utils.gdshaderinc"

vec2 rotate(vec2 uv, float angle) {
	float sa = sin(angle);
	float ca = cos(angle);
	return (uv - 0.5) * mat2(vec2(ca, -sa), vec2(sa, ca)) + 0.5;
}

float angle(vec2 uv) {
	vec2 d = uv - vec2(0.5);
	return atan(d.x, d.y) + PI;
}

void fragment() {
	vec4 original = COLOR;
	if (progress <= 0.0) {
		original.a *= base_alpha - 1.0;
		COLOR = original;
	} else {
		float stroke_progress = remap(progress, 0, 1, stroke_range.x, stroke_range.y);
		original.a *= base_alpha - smoothstep(stroke_progress - edge, stroke_progress + edge, angle(rotate(UV, PI)) / TAU);

		float cap_progress = remap(progress, 0, 1, cap_range.x, cap_range.y);
		vec4 cap = texture(edge_tex, rotate(UV, cap_progress * TAU));
		cap.a *= COLOR.a;
		COLOR = alpha_blend(original, cap);
	}
}
