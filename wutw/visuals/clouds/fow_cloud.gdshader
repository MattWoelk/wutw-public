shader_type canvas_item;

group_uniforms dynamic_state;
instance uniform vec4 global_rect;
uniform sampler2D fow_texture : filter_linear_mipmap_anisotropic;

group_uniforms clip;
uniform float clip_threshold : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float clip_distance : hint_range(0.0001, 0.1, 0.001) = 0.001;
uniform float clip_edge_threshold : hint_range(0.001, 1.0, 0.001) = 0.5;
uniform float clip_edge_distance : hint_range(0.001, 1.0, 0.001) = 0.02;
uniform float landmass_encroach_fade_from_scale : hint_range(0.001, 1.0, 0.001) = 0.54;

group_uniforms color;
uniform float range : hint_range(0.001, 10, 0.001) = 0.5;
uniform sampler2D gradient : filter_linear_mipmap_anisotropic;
uniform sampler2D gradient_near_land : filter_linear_mipmap_anisotropic;

group_uniforms detail_noise;
uniform float noise_scale : hint_range(1, 500) = 200;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;
uniform vec3 noise_color : source_color = vec3(0.0);

group_uniforms edge_noise;
uniform float edge_noise_scale : hint_range(1, 500) = 325;
uniform float edge_noise_strength : hint_range(0.0, 2.0) = 1.235;
uniform float edge_noise_smoothness : hint_range(0.01, 1.0) = 1.0;

group_uniforms randomization;
instance uniform float variation_random : hint_range(0.0, 1.0) = 0.0;

const float SCALE_CUTOFF = 0.2;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"
#include "res://visuals/clouds/cloud_sdf_shapes.gdshaderinc"

void fragment() {
	vec2 sdf_uv = UV - 0.5;

	// Sample distance mask at center for scale.
	float global_center_u = remap(0.5, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_center_v = remap(0.5, 0.0, 1.0, global_rect.y, global_rect.w);
	vec4 fow_sample_center = texture(fow_texture, vec2(global_center_u, global_center_v));
	float fow_dist_center = 1.0 - fow_sample_center.r;
	float landmass_dist_center = 0.95 - fow_sample_center.g;
	float clip_dist_center = max(fow_dist_center, landmass_dist_center);
	float scale = smoothstep(clip_threshold + clip_distance, clip_threshold, clip_dist_center);
	if (scale <= SCALE_CUTOFF) {
		discard;
	}
	sdf_uv /= scale;

	// Draw the shape.
	float dist = sdf_cloud_varied(sdf_uv, variation_random);

	// Part 2 of scale application.
	dist *= scale;

	// Sample distance mask at pixel.
	float global_u = remap(UV.x, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_v = remap(UV.y, 0.0, 1.0, global_rect.y, global_rect.w);
	vec4 fow_sample = texture(fow_texture, vec2(global_u, global_v));
	float fow_dist = 1.0 - fow_sample.r;
	float landmass_dist = 0.97 - fow_sample.g;
	float clip_dist = max(fow_dist, landmass_dist);

	// Calculate colors by converting the distance through a gradient.
	float dist_unit = remap(dist, -range, range, 0.0, 1.0);
	vec4 color_away_from_land = texture(gradient, vec2(dist_unit, 0.5));
	vec4 color_near_land = texture(gradient_near_land, vec2(dist_unit, 0.5));

	// Show edges where close to mask.
	float edge_alpha = smoothstep(clip_edge_threshold + clip_edge_distance, clip_edge_threshold, clip_dist);
	vec4 color = mix(color_near_land, color_away_from_land, edge_alpha);

	// Add internal noise.
	float noise_amount = noise_strength * value_noise_2_1_smooth(floor((UV + variation_random) * noise_scale), noise_smoothness);
	color.rgb = mix(color.rgb, noise_color, noise_amount);

	// Add edge noise.
	float edge_mask = remap(max(color_near_land.r, max(color_near_land.g, color_near_land.b)), 0.0, 0.9, 1.0, 0.0);
	if (edge_mask > 0.0) {
		float edge_noise = value_noise_2_1_smooth(floor((UV + variation_random) * edge_noise_scale), edge_noise_smoothness);
		color.a *= (1.0 - edge_noise_strength * edge_noise * edge_mask);
	}

	// Fade out at small scale.
	color.a *= remap(scale, landmass_encroach_fade_from_scale, SCALE_CUTOFF, 1.0, 0.0);

	// Assign final color and alpha.
	COLOR *= color;
}