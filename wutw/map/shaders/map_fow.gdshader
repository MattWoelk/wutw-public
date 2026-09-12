shader_type canvas_item;

group_uniforms base_color;
uniform float base_gradient_range : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform sampler2D base_gradient : filter_linear_mipmap_anisotropic;

group_uniforms noise;
uniform float border_threshold : hint_range(0, 1) = 0.3;
uniform float border_noise_scale : hint_range(1, 10000) = 1700;
uniform float border_noise_strength : hint_range(0.0, 2.0) = .957;
uniform float border_noise_smoothness : hint_range(0.01, 1.0) = 1.0;

uniform vec4 fow_color: source_color = vec4(1, 1, 1, 0.5);
uniform float border_size = 5.0;
uniform float uv_scale = 2.0;
uniform float uv_offset = 0.5;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	vec4 sample = texture(TEXTURE, UV * uv_scale - uv_offset);
	float fow_dist = sample.r;
	float cloud_dist = sample.g;

	float fow_dist_unit = remap(fow_dist, 0.5 - base_gradient_range, 0.5 + base_gradient_range, 0.0, 1.0);
	COLOR.rgb = vec3(1);
	COLOR.rgba *= texture(base_gradient, vec2(fow_dist_unit, 0.5));
	COLOR.a *= smoothstep(127.0 - border_size, 127.0 + border_size, cloud_dist * 255.0);

	vec2 square_uv = UV;
	square_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	float border_intensity = smoothstep(border_threshold, border_threshold * 0.6, max3(COLOR.r, COLOR.g, COLOR.b));
	float border_noise = value_noise_2_1_smooth(floor(square_uv * border_noise_scale), border_noise_smoothness);
	COLOR.a *= 1.0 - clamp(border_noise * border_noise_strength * border_intensity, 0.0, 1.0);
}
