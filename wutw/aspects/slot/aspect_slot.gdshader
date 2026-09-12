shader_type canvas_item;

const int SHAPE_CIRCLE = 0;
const int SHAPE_RECTANGLE = 1;
const int SHAPE_STAR = 2;

group_uniforms filled;
uniform sampler2D aspect_tex: repeat_disable, filter_linear_mipmap;
uniform float fade_blend : hint_range(0.0, 1.0) = 0.0;

group_uniforms frame;
uniform int frame_shape : hint_enum("Circle", "Rectangle", "Star") = 0;
uniform sampler2D frame_gradient: repeat_disable, filter_linear_mipmap;
uniform vec2 frame_size = vec2(0.2, 0.3);
uniform vec3 frame_color: source_color = vec3(1.0, 0.0, 0.0);
uniform float frame_gradient_scale : hint_range(0.1, 10) = 1.0;
uniform float frame_gradient_highlight_scale : hint_range(0.1, 10) = 0.8;
uniform float frame_size_highlight_scale : hint_range(0.1, 10) = 0.8;
uniform vec2 star_params = vec2(0.2, 0.3);
uniform sampler2D dashed_mask: repeat_disable, filter_linear_mipmap;

group_uniforms accessible;
uniform bool is_accessible = false;
uniform bool is_super_accessible = false;
uniform sampler2D accessible_filled_tex: repeat_disable, filter_linear_mipmap;
uniform sampler2D accessible_empty_tex: repeat_disable, filter_linear_mipmap;
uniform sampler2D accessible_highlighted_tex: repeat_disable, filter_linear_mipmap;

group_uniforms noise;
uniform float noise_scale : hint_range(0.01, 100) = 0.5;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec3 noise_color : source_color = vec3(0.0);

group_uniforms dynamic;
uniform float fade_progress : hint_range(0.0, 1.0) = 0.0;
uniform float highlight : hint_range(0.0, 1.0) = 0.0;
uniform bool dashed = false;

#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

vec4 add_noise(vec2 uv, vec4 color) {
	float noise = value_noise_2_1(floor(uv * noise_scale));
	float brightness = max(max(color.r, color.g), color.b);
	float dist_from_center = 1.0 - distance(vec2(0.5, 0.5), uv);
	return vec4(mix(color.rgb, noise_color, noise * noise_strength * brightness * dist_from_center),
			    mix(color.a, 0.0, (1.0 - noise) * noise_strength));
}

void fragment() {
	float slot_dist = 0.0;
	float used_gradient_scale = frame_gradient_scale;
	if (frame_shape == SHAPE_CIRCLE) {
		used_gradient_scale = mix(frame_gradient_scale, frame_gradient_scale * frame_gradient_highlight_scale, highlight);
		vec2 used_frame_size = mix(frame_size, frame_size * frame_size_highlight_scale, highlight);
		slot_dist = sdf_circle(UV - 0.5, used_frame_size.x);
	} else if (frame_shape == SHAPE_RECTANGLE) {
		used_gradient_scale = mix(frame_gradient_scale, frame_gradient_scale * frame_gradient_highlight_scale, highlight);
		vec2 used_frame_size = mix(frame_size, frame_size * frame_size_highlight_scale, highlight);
		slot_dist = sdf_box(UV - 0.5, used_frame_size);
	} else if (frame_shape == SHAPE_STAR) {
		used_gradient_scale = mix(frame_gradient_scale, frame_gradient_scale * frame_gradient_highlight_scale, highlight);
		used_gradient_scale *= 2.2;
		slot_dist = -sdf_star(vec2(UV.x, 0.1 + (1.0 - UV.y) / 1.1) - 0.5, star_params.x, 5, star_params.y);
	}
	vec4 slot_color;
	if (is_accessible && frame_shape != SHAPE_STAR) {
		vec4 empty_color = texture(accessible_empty_tex, UV);
		vec4 highlighted_color = texture(accessible_highlighted_tex, UV);
		slot_color = mix(empty_color, highlighted_color, highlight);
	} else {
		slot_color = vec4(frame_color, texture(frame_gradient, vec2(slot_dist * used_gradient_scale, 0)).r);
	}

	vec4 filled_color;
	if (frame_shape == SHAPE_STAR) {
		filled_color = vec4(frame_color, texture(frame_gradient, vec2(slot_dist, 0)).r);
	} else {
		if (is_accessible) {
			filled_color = texture(accessible_filled_tex, UV);
		} else {
			filled_color = texture(aspect_tex, UV);
		}
	}

	if (is_super_accessible) {
		slot_color.rgb = mix(vec3(1), slot_color.rgb, slot_color.a);
		slot_color.a = max(slot_color.a, filled_color.a * 0.65);
	}

	float fade_dist = sdf_circle(UV - 0.5, 0.65 - fade_progress * 0.76);
	vec4 color = mix(slot_color, filled_color, smoothstep(0, fade_blend, fade_dist));

	if (dashed) {
		float dashed_alpha = texture(dashed_mask, UV).r;
		if (is_super_accessible) {
			dashed_alpha = max(dashed_alpha, smoothstep(0.0, 0.35, filled_color.a - slot_color.a));
		}
		color.a *= mix(1.0, dashed_alpha, highlight);
	}

	color = add_noise(UV, color);

	COLOR *= color;
}
