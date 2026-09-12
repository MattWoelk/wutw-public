shader_type canvas_item;

group_uniforms dynamic_state;
instance uniform vec4 global_rect;
uniform sampler2D landmass_sdf : filter_linear_mipmap_anisotropic;
uniform sampler2D land_depth_texture : filter_linear_mipmap_anisotropic;
instance uniform float variation_random : hint_range(0.0, 1.0) = 0.0;

group_uniforms landmass_intersect;
uniform float landmass_edge_threshold : hint_range(0.001, 1.0, 0.001) = 0.5;
uniform float landmass_edge_distance : hint_range(0.001, 1.0, 0.001) = 0.02;

group_uniforms color;
uniform float distance_to_color_range : hint_range(0.001, 10, 0.001) = 0.119;
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

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/clouds/cloud_sdf_shapes.gdshaderinc"

/////////////  MAIN  /////////////

void fragment() {
	vec2 sdf_uv = UV - 0.5;

	// Draw the shape.
	float dist = sdf_cloud_varied(sdf_uv, variation_random);

	// Calculate colors by converting the distance through a gradient.
	float dist_unit = remap(dist, -distance_to_color_range, distance_to_color_range, 0.0, 1.0);
	vec4 color_away_from_land = texture(gradient, vec2(dist_unit, 0.5));
	vec4 color_near_land = texture(gradient_near_land, vec2(dist_unit, 0.5));

	// Show edges where intersecting landmass.
	float global_u = remap(UV.x, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_v = remap(UV.y, 0.0, 1.0, global_rect.y, global_rect.w);
	float distance_to_landmass = texture(landmass_sdf, vec2(global_u, global_v)).r;
	float normalized_distance_to_landmass = remap(
		distance_to_landmass, landmass_edge_threshold - landmass_edge_distance, landmass_edge_threshold, 0.0, 1.0);
	vec4 color = mix(color_away_from_land, color_near_land, normalized_distance_to_landmass);


	// Determine the Z as the primary alpha mask.
	float land_z = texture(land_depth_texture, vec2(global_u, global_v)).r;
	float cloud_z = remap(0.5, 0.0, 1.0, global_rect.y, global_rect.w);
	float z_diff = cloud_z - land_z;
	color.a *= smoothstep(0.0, 0.1, z_diff);

	// Add internal noise.
	float noise_amount = noise_strength * value_noise_2_1_smooth(floor((UV + variation_random) * noise_scale), noise_smoothness);
	color.rgb = mix(color.rgb, noise_color, noise_amount);

	// Add edge noise.
	float edge_mask = remap(max(color_near_land.r, max(color_near_land.g, color_near_land.b)), 0.0, 0.9, 1.0, 0.0);
	edge_mask = mix(0.0, edge_mask, normalized_distance_to_landmass);
	if (edge_mask > 0.0) {
		float edge_noise = value_noise_2_1_smooth(floor((UV + variation_random) * edge_noise_scale), edge_noise_smoothness);
		color.a *= (1.0 - edge_noise_strength * edge_noise * edge_mask);
	}

	// Assign final color and alpha.
	COLOR = color;
	//COLOR.rgba = vec4(z_diff * 0., land_z, 0., 1.0);
}
