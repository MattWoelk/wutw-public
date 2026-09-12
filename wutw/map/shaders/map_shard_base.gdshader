shader_type canvas_item;

group_uniforms clipping;
uniform float clip_width: hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms base_color;
uniform sampler2D base_color: source_color;
uniform float bottom_shade_extent: hint_range(0.0, 255.0, 0.1) = 10.0;

group_uniforms lighting;
uniform sampler2D texture_nearest: filter_nearest;
uniform vec2 light_direction = vec2(1.0, 1.0);
uniform vec3 lit_color: source_color = vec3(1.0, 1.0, 1.0);
uniform float light_intensity: hint_range(0.0, 1.0, 0.01) = 1.0;

group_uniforms border;
uniform float border_width: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform vec3 border_color: source_color = vec3(0.0, 0.0, 0.0);
uniform float noise_scale : hint_range(1, 10000) = 1700;
uniform float noise_strength : hint_range(0.0, 2.0) = .957;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;

group_uniforms pattern;
uniform sampler2D pattern: repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D pattern_detail: repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D pattern_noise: repeat_enable, filter_linear_mipmap_anisotropic;
uniform float pattern_scale: hint_range(0.001, 100.0, 0.01) = 30.0;
uniform float pattern_detail_scale: hint_range(0.001, 100.0, 0.01) = 30.0;
uniform float pattern_edge_fade: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float pattern_intensity: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float pattern_detail_intensity: hint_range(0.0, 10.0, 0.01) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

vec2 angle_to_normal(float a) {
    return vec2(cos(a), sin(a));
}

void fragment() {
	// Unpack sample.
	vec4 sample = texture(TEXTURE, UV);
	float min_dist_to_edge = sample.r;
	float dist_from_top_raw = sample.g;
	float min_dist_to_area = sample.a;

	// Shape alpha.
	float alpha = smoothstep(1.0 - clip_width, 1.0, min_dist_to_area);
	COLOR.a *= alpha;

	// Base top-bottom gradient.
	float dist_y = dist_from_top_raw * 255.0;
	float top_bottom_t = clamp(dist_y / bottom_shade_extent, 0.0, 1.0);
	COLOR.rgb = texture(base_color, vec2(top_bottom_t, 0)).rgb;

	// Pattern.
	vec2 square_uv = UV;
	square_uv.x *= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	vec3 pattern_color = texture(pattern, square_uv * pattern_scale).rgb;
	vec3 pattern_detail_color = texture(pattern_detail, square_uv * pattern_detail_scale).rgb;
	float pattern_noise_sample = texture(pattern_noise, UV).r;
	float pattern_fade_intensity = smoothstep(0, (pattern_edge_fade / 10.0), abs(min_dist_to_edge));
	COLOR.rgb *= mix(vec3(1.0), pattern_color, pattern_intensity * pattern_fade_intensity);
	COLOR.rgb *= mix(vec3(1.0), pattern_detail_color, pattern_detail_intensity * pattern_fade_intensity * pattern_noise_sample);

	// Lighting.
	vec4 sample2 = texture(texture_nearest, UV);
	float angle_raw = sample2.b;
	vec2 normal = angle_to_normal(angle_raw * TAU);
	if (min_dist_to_edge < 0.025)  // At edges the interpolated angle is noise.
	{
		normal = vec2(1.0, 0.0);
	}
	float light_effect = clamp(1.0 - dot(normal, normalize(light_direction)), 0, 1);
	COLOR.rgb += lit_color * light_intensity * light_effect;

	// Border.
	if (border_width > 0.0)
	{
		float border_intensity = 1.0 - smoothstep(0, (border_width / 10.0), min_dist_to_edge);
		float noise = value_noise_2_1_smooth(floor(UV * noise_scale), noise_smoothness);
		border_intensity *= clamp(1.0 - noise * noise_strength, 0.0, 1.0);
		
		// HACK: Cliffsides on the top side of the map have buggy min_dist_to_edge.
		if (border_intensity <= 0.0) {
			float left_alpha = texture(TEXTURE, UV - vec2(0.0015, 0)).a;
			float right_alpha = texture(TEXTURE, UV + vec2(0.0015, 0)).a;
			if (left_alpha <= 0.0 || right_alpha <= 0.0) {
				border_intensity = .7;
			}
		}
		
		COLOR.rgb = mix(COLOR.rgb, border_color, border_intensity);
		
		
	}
}
