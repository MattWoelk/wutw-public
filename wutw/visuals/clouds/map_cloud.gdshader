shader_type canvas_item;

group_uniforms dynamic_state;
instance uniform vec4 global_rect;
uniform sampler2D landmass_sdf : filter_linear_mipmap_anisotropic;
instance uniform float variation_random : hint_range(0.0, 1.0) = 0.0;

group_uniforms landmass_intersect;
uniform float landmass_edge_threshold : hint_range(0.001, 1.0, 0.001) = 0.5;
uniform float landmass_edge_distance : hint_range(0.001, 1.0, 0.001) = 0.02;
uniform float landmass_encroach_threshold : hint_range(-1.0, 1.0, 0.001) = 0.332;
uniform float landmass_encroach_distance : hint_range(0.001, 1.0, 0.001) = 0.381;
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

const float SCALE_CUTOFF = 0.01;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"
#include "res://visuals/clouds/cloud_sdf_shapes.gdshaderinc"

/////////////  NOISE  /////////////

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D value noise with smooth interpolation
float noise(vec2 p, float smoothness) {
	vec2 i = floor(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = vec2(smoothness / 2.0);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/////////////  MAIN  /////////////

void fragment() {
	vec2 sdf_uv = UV - 0.5;

	// Shrink based on distance to landmass.
	float global_center_u = remap(0.5, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_center_v = remap(0.5, 0.0, 1.0, global_rect.y, global_rect.w);
	float distance_center_to_landmass = texture(landmass_sdf, vec2(global_center_u, global_center_v)).r;
	float scale = remap(distance_center_to_landmass,
		landmass_encroach_threshold, landmass_encroach_threshold + landmass_encroach_distance, 1.0, 0.0);
	if (scale <= SCALE_CUTOFF) {
		discard;
	}
	sdf_uv /= scale;

	// Draw the shape.
	float dist = sdf_cloud_varied(sdf_uv, variation_random);

	// Part 2 of scale application.
	dist *= scale;

	// Calculate colors by converting the distance through a gradient.
	float dist_unit = remap(dist, -range, range, 0.0, 1.0);
	vec4 color_away_from_land = texture(gradient, vec2(dist_unit, 0.5));
	vec4 color_near_land = texture(gradient_near_land, vec2(dist_unit, 0.5));

	// Show edges where intersecting landmass.
	float global_u = remap(UV.x, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_v = remap(UV.y, 0.0, 1.0, global_rect.y, global_rect.w);
	float distance_to_landmass = texture(landmass_sdf, vec2(global_u, global_v)).r;
	float normalized_distance_to_landmass = remap(
		distance_to_landmass, landmass_edge_threshold - landmass_edge_distance, landmass_edge_threshold, 0.0, 1.0);
	vec4 color = mix(color_away_from_land, color_near_land, normalized_distance_to_landmass);

	// Add internal noise.
	float noise_amount = noise_strength * noise(floor((UV + variation_random) * noise_scale), noise_smoothness);
	color.rgb = mix(color.rgb, noise_color, noise_amount);

	// Add edge noise.
	float edge_mask = remap(max(color_near_land.r, max(color_near_land.g, color_near_land.b)), 0.0, 0.9, 1.0, 0.0);
	edge_mask = mix(0.0, edge_mask, normalized_distance_to_landmass);
	if (edge_mask > 0.0) {
		float edge_noise = noise(floor((UV + variation_random) * edge_noise_scale), edge_noise_smoothness);
		color.a *= (1.0 - edge_noise_strength * edge_noise * edge_mask);
	}

	// Fade out at small scale.
	color.a *= remap(scale, landmass_encroach_fade_from_scale, SCALE_CUTOFF, 1.0, 0.0);

	// Assign final color and alpha.
	COLOR = color;

	//COLOR.rgba = vec4(scale, 0.0, 0.0, 1.0);
	//COLOR.rgba = vec4(distance_to_landmass, 0.0, 0.0, 1.0);
	//COLOR.rgba = vec4(edge_mask, 0.0, 0.0, 1.0);
}