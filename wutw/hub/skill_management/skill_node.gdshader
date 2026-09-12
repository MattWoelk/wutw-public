shader_type canvas_item;

group_uniforms colors;
uniform vec4 unknown_color : source_color = vec4(0, 0, 0, 1);
uniform vec4 unavailable_color : source_color = vec4(0, 0, 0, 1);
uniform vec4 available_color : source_color = vec4(0, 0, 0, 1);
uniform vec4 unlocked_color : source_color = vec4(0, 0, 0, 1);
uniform vec3 hovered_color : source_color = vec3(0.5, 0.5, 0.5);

group_uniforms frame;
uniform float radius : hint_range(0.0, 1.0) = 0.8;
uniform float frame_width : hint_range(0.0, .3) = 0.1;
uniform float frame_smoothness : hint_range(0.0, .3) = 0.1;
uniform float margin : hint_range(0.0, 1.0) = 0.1;

group_uniforms noise;
uniform float noise_scale : hint_range(0.01, 100) = 0.5;
uniform float noise_strength : hint_range(0.0, 5.0) = 0.25;
uniform float noise_smoothness : hint_range(0.0, 1.0) = 0.5;
uniform float noise_min : hint_range(0.0, 1.0) = 0.2;
uniform float noise_max : hint_range(0.0, 1.0) = 0.8;

group_uniforms lines;
uniform vec4 color: source_color = vec4(0, 0, 0, 1.0);
uniform float width: hint_range(0.0, 0.2, 0.001) = 0.015;
uniform float edge: hint_range(0.0, 0.2, 0.001) = 0.005;
uniform float lines_margin: hint_range(0.0, 0.2, 0.001) = 0.015;

const int STATE_UNKNOWN = 0;
const int STATE_UNAVAILABLE = 1;
const int STATE_AVAILABLE = 2;
const int STATE_UNLOCKED = 3;
const int STATE_EMPTY = 4;

#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

vec4 draw_icon(sampler2D icon_tex, vec2 uv, int state, bool root, bool new, bool hovered) {
	vec4 result;

	// Alpha
	float icon_alpha = 1.0 - texture(icon_tex, remap2(uv, 0.0, 1.0, -margin / 0.5, 1.0 + margin / 0.5)).r;
	icon_alpha = min(icon_alpha, distance(vec2(0.5), uv) <= (0.5 - margin) ? 1.0 : 0.0);
	float dist = sdf_circle(uv - 0.5, radius + frame_width / 2.0);
	float frame_alpha = min(
		smoothstep(frame_smoothness, 0, sdf_circle(uv - 0.5, radius + frame_width / 2.0)),
		1.0 - smoothstep(frame_smoothness, 0, sdf_circle(uv - 0.5, radius - frame_width / 2.0)));

	// State
	if (state == STATE_UNKNOWN) {
		result = unknown_color;
	} else if (state == STATE_UNAVAILABLE) {
		result = unavailable_color;
	} else if (state == STATE_AVAILABLE) {
		result = available_color;
	} else if (state == STATE_UNLOCKED) {
		result = unlocked_color;
	}

	if (root) {
		result.a *= icon_alpha;
	} else {
		if (new && state != STATE_UNLOCKED) {
			vec2 center_uv = uv - 0.5;
			float angle = atan(center_uv.y, center_uv.x);
			result.rgb += pow(remap(sin(angle - TIME * 2.0), -1, 1, 0.0, 1.0), 6.0) * frame_alpha;
		}
		result.a *= max(frame_alpha, icon_alpha);
	}

	// Hover
	if (hovered) {
		result.rgb = mix(result.rgb, hovered_color, frame_alpha);
	}

	return result;
}

vec4 draw_lines(vec2 uv, int state, bool line_left, bool line_right, bool line_up, bool line_down, bool line_upleft, bool line_upright, bool line_downleft, bool line_downright) {
	uv = remap2(uv, vec2(0), vec2(1), vec2(-lines_margin), vec2(1.0 + lines_margin));

	float accum = 0.0;
	vec2 origin = vec2(0.5, 0.5);
	if (line_left) {
		float dist = sdf_line(uv, origin, vec2(0, 0.5));
		accum += smoothstep(width + edge, width, dist);
	}
	if (line_right) {
		float dist = sdf_line(uv, origin, vec2(1.0, 0.5));
		accum += smoothstep(width + edge, width, dist);
	}
	if (line_up) {
		float dist = sdf_line(uv, origin, vec2(0.5, 0.0));
		accum += smoothstep(width + edge, width, dist);
	}
	if (line_down) {
		float dist = sdf_line(uv, origin, vec2(0.5, 1.0));
		accum += smoothstep(width + edge, width, dist);
	}

	if (line_upleft) {
		float dist = sdf_line(uv, vec2(0, 0), origin);
		accum += smoothstep(width + edge, width, dist);
	}
	if (line_upright) {
		float dist = sdf_line(uv, vec2(1.0, 0), origin);
		accum += smoothstep(width + edge, width, dist);
	}
	if (line_downleft) {
		float dist = sdf_line(uv, vec2(0, 1.0), origin);
		accum += smoothstep(width + edge, width, dist);
	}
	if (line_downright) {
		float dist = sdf_line(uv, vec2(1.0, 1.0), origin);
		accum += smoothstep(width + edge, width, dist);
	}

	vec4 result = color;
	result.a *= clamp(accum, 0.0, 1.0);

	if (state != STATE_EMPTY) {
		float dist_to_center = length(uv - vec2(0.5));
		if (dist_to_center < radius + frame_width) {
			result.a *= smoothstep(radius + frame_width * 0.5, radius + frame_width, dist_to_center);
		}
	}

	return result;
}

varying flat vec4 raw_modulate;

void vertex() {
    raw_modulate = COLOR;
}

void fragment() {
	int chunk1 = int(round(raw_modulate.r * 255.0));
	int chunk2 = int(round(raw_modulate.g * 255.0));
	int packed_state = chunk1 | (chunk2 << 8);

	int state = packed_state & 7;
	bool hovered = bool((packed_state >> 3) & 1);
	bool root = bool((packed_state >> 4) & 1);
	bool new = bool((packed_state >> 5) & 1);

	bool line_left = bool((packed_state >> 6) & 1);
	bool line_right = bool((packed_state >> 7) & 1);
	bool line_up = bool((packed_state >> 8) & 1);
	bool line_down = bool((packed_state >> 9) & 1);
	bool line_upleft = bool((packed_state >> 10) & 1);
	bool line_downleft = bool((packed_state >> 11) & 1);
	bool line_upright = bool((packed_state >> 12) & 1);
	bool line_downright = bool((packed_state >> 13) & 1);

	vec4 icon = state == STATE_EMPTY ? vec4(0) : draw_icon(TEXTURE, UV, state, root, new, hovered);
	vec4 lines = draw_lines(UV, state, line_left, line_right, line_up, line_down, line_upleft, line_upright, line_downleft, line_downright);
	COLOR = alpha_blend(icon, lines);

	// Noise
	float noise = value_noise_2_1_smooth(floor(UV * noise_scale), noise_smoothness);
	COLOR.a = mix(COLOR.a, COLOR.a * remap(noise, 0, 1, noise_min, noise_max), noise_strength);
}
