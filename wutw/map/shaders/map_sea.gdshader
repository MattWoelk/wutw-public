shader_type canvas_item;

group_uniforms base_color;
uniform float base_gradient_range : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform sampler2D base_gradient : filter_linear_mipmap_anisotropic;

group_uniforms distortion;
uniform float distortion_amplitude : hint_range(0.0001, 0.1) = 0.024;
uniform float distortion_frequency : hint_range(0.001, 500) = 110.0;
uniform vec2 distortion_range = vec2(0.4, 0.205);

group_uniforms noise;
uniform sampler2D noise: filter_linear_mipmap_anisotropic, repeat_enable;
uniform float border_threshold : hint_range(0, 1) = 0.3;
uniform float border_noise_scale : hint_range(1, 10000) = 1700;
uniform float border_noise_strength : hint_range(0.0, 2.0) = .957;
uniform float border_noise_smoothness : hint_range(0.01, 1.0) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	float area_dist = texture(TEXTURE, UV).r;
	float area_dist_unit = remap(area_dist, 0.5 - base_gradient_range, 0.5 + base_gradient_range, 0.0, 1.0);
	COLOR.rgba = texture(base_gradient, vec2(area_dist_unit, 0.5));
	vec2 square_uv = UV;
	square_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	COLOR.a *= texture(noise, square_uv).r;

	float border_intensity = smoothstep(border_threshold, border_threshold * 0.6, max3(COLOR.r, COLOR.g, COLOR.b));
	float border_noise = value_noise_2_1_smooth(floor(square_uv * border_noise_scale), border_noise_smoothness);
	COLOR.a *= 1.0 - clamp(border_noise * border_noise_strength * border_intensity, 0.0, 1.0);
}
