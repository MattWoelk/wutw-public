shader_type canvas_item;

group_uniforms dynamic;
uniform float path_length = 100.0;
uniform float progress : hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms shape;
uniform float starting_length : hint_range(0.00, 100.0) = 10.0;
uniform vec2 width_thresholds = vec2(0.7, 1.0);
uniform float wave_frequency : hint_range(0.01, 1.0) = 0.1;
uniform float waviness : hint_range(0.01, 1.0) = 0.1;

group_uniforms overlay;
uniform sampler2D bokashi_texture: repeat_enable;
uniform float overlay_offset_vertical = 0.0;
uniform float overlay_multiplier_u: hint_range(0.001, 1.0) = 1.0;
uniform float overlay_multiplier_v: hint_range(0.001, 1.0) = 1.0;

group_uniforms border;
uniform float min_border : hint_range(0.0, 1.0) = 0.568;
uniform float border_size : hint_range(0.0, 1.0) = 0.255;

group_uniforms border_noise;
uniform float noise_scale : hint_range(1, 10) = 1;
uniform vec3 border_color: source_color = vec3(0.0,0.0,0.0);
uniform float noise_strength : hint_range(0.0, 2.0) = 1.104;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 0.623;
uniform float noise_uv_ratio : hint_range(0.001, 2.0) = 1;

#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	// Define shape.
	float side = UV.y < 0.5 ? UV.y * 2.0 : (1.0 - UV.y) * 2.0;
	float t = UV.x;
	side -= waviness + sin(t * path_length * wave_frequency) * waviness;
	vec4 base_color = texture(TEXTURE, vec2(side, t));
	base_color.a = smoothstep(width_thresholds.x, width_thresholds.y, side);

	// Add a detail texture.
	vec2 overlay_uv = vec2(t * path_length * overlay_multiplier_u,
						   UV.y * overlay_multiplier_v + overlay_offset_vertical);
	vec3 overlay_color = texture(bokashi_texture, overlay_uv).rgb;
	vec3 textured_color;
	for (int i = 0; i < 3; ++i) {
		if (base_color[i] < 0.5) {
	    	textured_color[i] = 2.0 * base_color[i] * overlay_color[i];
		} else {
		    textured_color[i] = 1.0 - 2.0 * (1.0 - base_color[i]) * (1.0 - overlay_color[i]);
		}
	}

	// Add border noise.
	vec2 square_uv = UV;
	square_uv.x *= path_length;
	square_uv.y /= noise_uv_ratio;
	float noise = value_noise_2_1_smooth(floor(square_uv * noise_scale), noise_smoothness);
	float border_amount = 1.0 - side;
	float cap = 1.0 - min(smoothstep(0, 0.02, UV.r), 1.0 - smoothstep(0.98, 1.0, UV.r));
	border_amount = clamp(max(border_amount, cap), 0.0, 1.0);
	float border_intensity = smoothstep(min_border, min_border + border_size, border_amount);
	vec4 color;
	color.rgb = mix(textured_color.rgb, border_color, border_intensity);
	color.a = base_color.a - clamp(1.0 - noise * noise_strength, 0.0, 1.0) * border_intensity;
	
	// Fade out ends.
	float cur_length = t * path_length;
	if (cur_length < starting_length) {
		color.a *= smoothstep(1.0, starting_length, cur_length);
	}
	if (path_length - cur_length < starting_length) {
		color.a *= smoothstep(1.0, starting_length, path_length - cur_length);
	}
	
	// Fade in progress.
	color.a *= smoothstep(progress, progress - 0.1, t);
	
	COLOR.rgb = color.rgb;
	COLOR.a *= color.a;
}
