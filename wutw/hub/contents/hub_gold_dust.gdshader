shader_type canvas_item;

uniform sampler2D main_noise: repeat_enable;
uniform sampler2D detail_noise: repeat_enable;
uniform float detail_noise_scale : hint_range(.01, 100) = 1.0;
uniform float detail_intensity : hint_range(.01, 1.0) = 0.6;
uniform float distance_cut_off = 50.0; // px
uniform float shine_noise_scale : hint_range(.01, 1.0) = 1.0;
uniform vec2 shine_amount = vec2(-0.5, 0.5);

#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	// Don't show over the hub.
    vec2 at = screen_uv_to_sdf(SCREEN_UV);
	float sdf_mask = clamp((texture_sdf(at)+ distance_cut_off / 2.0) / distance_cut_off, 0, 1);

	float main_sample = texture(main_noise, UV).r;
	vec2 square_uv = UV;
	square_uv.y /= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float detail_sample = texture(detail_noise, square_uv * detail_noise_scale).r;
	COLOR.a *= main_sample * detail_sample * sdf_mask;
	// Darken edges/outline.
	COLOR.rgb -= (1.0 - detail_sample) * detail_intensity;

	// Add shine on viewport move.
	float shine_sample = texture(detail_noise, (square_uv - vec2(FRAGCOORD.x / 2000.0, 0.0)) * shine_noise_scale).r;
	vec3 hsv = rgb2hsv(COLOR.rgb);
	hsv.y += remap(shine_sample, 0, 1, shine_amount.x, shine_amount.y);
	hsv.z += remap(shine_sample, 0, 1, shine_amount.x, shine_amount.y);
	COLOR.rgb = hsv2rgb(hsv);
}
