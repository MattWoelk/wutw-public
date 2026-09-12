shader_type canvas_item;
//render_mode blend_sub;

group_uniforms paper;
uniform vec3 paper_color : source_color = vec3(1);
uniform vec3 modulate : source_color = vec3(1);

group_uniforms key;
uniform vec3 key_color : source_color = vec3(0);
uniform float max_key_lum_dist: hint_range(0.0, 1, 0.01) = 0.1;
uniform float max_key_hue_dist: hint_range(0.0, 1, 0.01) = 0.1;
uniform float key_boost: hint_range(0.1, 5, 0.01) = 1.5;

group_uniforms colors;
uniform int palette_count = 0;
uniform vec3 palette_starts[10] : source_color;
uniform vec3 palette_ends[10] : source_color;
uniform int debug_palette_display = -3;

group_uniforms animation;
uniform float progress: hint_range(0.0, 1.0, 0.01) = 0;

#include "res://visuals/shaders/utils.gdshaderinc"

float range_diff(float value, float a, float b, float inside_factor) {
	if (value < min(a, b)) {
		return min(a, b) - value;
	} else if (value > max(a, b)) {
		return value - min(a, b);
	} else {
		float avg_hue = (a + b) / 2.0;
		float hue_range = abs(a - b);
		return inside_factor * (1.0 - (abs(value - avg_hue) / hue_range));
	}
	return 1.0;
}

float ink_color_match(vec3 color, vec3 start, vec3 end) {
	vec3 source_hsv = rgb2hsv(color);
	vec3 start_hsv = rgb2hsv(start);
	vec3 end_hsv = rgb2hsv(end);

	float hue_diff = range_diff(source_hsv.r, start_hsv.r, end_hsv.r, 0.1);
	float sat_diff = range_diff(source_hsv.g, start_hsv.g, end_hsv.r, 0.1);
	float val_diff = range_diff(source_hsv.b, start_hsv.b, end_hsv.r, 0.1);

	return remap(hue_diff, -0.1, .7, 1, 0.0)
		 + remap(sat_diff, -0.1, 1.0, 1, 0.0)
		 + remap(val_diff, -0.1, 1.0, 1, 0.0);
}

vec3 extract_ink_color(vec3 color) {
	return 1.0 - clamp((paper_color - color) / paper_color, 0, 1);
}

float progress_to_opacity(float pass_progress, vec2 uv, int pass_index) {
	if (pass_index % 2 == 0) {
		return smoothstep(pass_progress + 0.1, pass_progress, uv.x) * pass_progress;
	} else {
		return smoothstep(pass_progress + 0.1, pass_progress, 1.0 - uv.x) * pass_progress;
	}
}

void fragment() {
	vec3 ink_color = extract_ink_color(COLOR.rgb);

	int best_index = -1;
	float best_index_match = ink_color_match(ink_color, vec3(1), vec3(1));
	float matches[10];
	//float best_index_match = ink_color_match(COLOR.rgb, paper_color, paper_color);
	for (int i = 0; i < palette_count; ++i) {
		matches[i] = ink_color_match(ink_color, extract_ink_color(palette_starts[i]), extract_ink_color(palette_ends[i]));
		if (matches[i] > best_index_match) {
			best_index_match = matches[i];
			best_index = i;
		}
	}
	bool is_paper = best_index == -1;

	vec3 nonkey_color;
	if (best_index == -1) {
		nonkey_color = vec3(1);
	} else {
		nonkey_color = mix(extract_ink_color(palette_starts[best_index]),
						  extract_ink_color(palette_ends[best_index]), 0.5);
	}

	//vec3 source_hsv = rgb2hsv(textureLod(TEXTURE, UV, 0).rgb);
	vec3 source_hsv = 1.0 - clamp((nonkey_color - COLOR.rgb) / nonkey_color, 0, 1);
	vec3 key_hsv = rgb2hsv(extract_ink_color(key_color));
	float lum_dist = abs(source_hsv.b - key_hsv.b);
	float hue_dist = abs(source_hsv.r - key_hsv.r);
	bool is_key = lum_dist < max_key_lum_dist && hue_dist < max_key_hue_dist;

	// DEBUG: palette matches display.
	if (debug_palette_display >= -1) {
		COLOR.rgb = ink_color;
		if (best_index == debug_palette_display) {
			COLOR.a = 1.0;
		} else {
			COLOR.a = 0.0;
		}
	} else if (debug_palette_display == -2) {
		if (is_key) {
			COLOR.rgb = key_color;
			COLOR.a = clamp(key_boost * lum_dist / max_key_lum_dist * hue_dist / max_key_hue_dist, 0, 1);
		} else if (best_index == -1) {
			COLOR.rgb = vec3(1);
		} else {
			COLOR.rgb = mix(extract_ink_color(palette_starts[best_index]),
						    extract_ink_color(palette_ends[best_index]), 0.5);
		}
	}

	if (is_paper) {
		COLOR.a = progress;
	} else {
		const float KEY_TIME_RANGE = 0.1;
		float key_opacity = clamp(key_boost * lum_dist / max_key_lum_dist * hue_dist / max_key_hue_dist, 0, 1);
		if (progress <= KEY_TIME_RANGE) {
			// Key only.
			if (is_key) {
				COLOR.rgb = key_color;
				COLOR.a = key_opacity * progress_to_opacity(progress / KEY_TIME_RANGE, UV, 0);
			} else {
				COLOR.a = 0.0;
			}
		} else {
			int pass_num = best_index;
			float pass_start = 0.1 + float(pass_num) * 0.9 / float(palette_count);
			float pass_end = 0.1 + float(pass_num + 1) * 0.9 / float(palette_count);
			float pass_progress = remap(progress, pass_start, pass_end, 0.0, 1.0);
			float opacity = progress_to_opacity(pass_progress, UV, pass_num + 1);
			if (is_key) {
				COLOR.rgb = mix(key_color, COLOR.rgb, opacity);
				COLOR.a = mix(key_opacity, 1.0, opacity);
			} else {
				COLOR.a = opacity;
			}
		}
	}

	//COLOR.rgb = (1.0 - COLOR.rgb) * modulate;  // For subtractive render mode.
}
