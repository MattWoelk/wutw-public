shader_type canvas_item;

group_uniforms shapes;
const int NUM_ELLIPSES = 12;
uniform vec4[NUM_ELLIPSES] ellipses;

group_uniforms smoothness;
uniform float merge_k : hint_range(0.001, 0.1, 0.001) = 0.1;

group_uniforms distortion;
uniform float distortion_amplitude : hint_range(0.0001, 0.1) = 0.01;
uniform float distortion_frequency : hint_range(0.001, 100) = 10.0;
uniform float distortion_speed : hint_range(0.001, 10) = 1.0;

//group_uniforms density_noise;
//uniform sampler2D density_noise : repeat_enable, filter_linear_mipmap_anisotropic;

group_uniforms color;
uniform float range : hint_range(0.001, 10, 0.001) = 0.5;
uniform sampler2D gradient : filter_linear_mipmap_anisotropic;
uniform sampler2D gradient_backup : filter_linear_mipmap_anisotropic;

group_uniforms detail_noise;
uniform float noise_scale : hint_range(1, 500) = 200;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;
uniform vec3 noise_color : source_color = vec3(0.0);

group_uniforms randomization;
uniform float variation_random : hint_range(0.0, 1.0) = 0.0;

group_uniforms debug;
uniform bool debug = false;
uniform sampler2D gradient_debug : filter_linear_mipmap_anisotropic;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D value noise with smooth interpolation
float noise(vec2 p) {
	vec2 i = floor(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = vec2(noise_smoothness / 2.0);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float sdf_cloud_piece(vec2 p, vec2 position, vec2 size, float random_seed) {
	size *= 1.0 + 10.0*sin(random_seed * TAU + TIME * distortion_speed) * distortion_amplitude;
	return sdf_ellipse(translate(p, position), size);
}

void fragment() {
	vec2 uv = UV - 0.5;

	//uv = distort(uv, 1.0 / distortion_amplitude, distortion_frequency, TIME * distortion_speed);

	float dist = 1.0;
	for (int i = 0; i < NUM_ELLIPSES; ++i)
	{
		vec4 ellipse_config = ellipses[i];
		if (ellipse_config.z > 0.0) {
			//ellipse_config.zw *= 1.0 + 10.0*sin(variation_random * TAU + TIME * distortion_speed + float(i) * 0.6) * distortion_amplitude;
			//float ellipse_dist = sdf_ellipse(translate(uv, ellipse_config.xy), ellipse_config.zw);
			// sdf_cloud_piece(uv, ellipse_config.xy, ellipse_config.zw, variation_random + float(i) * 0.6)
			//variation_random + float(i) * 0.6;
			//ellipse_dist += sin(variation_random * TAU + TIME * distortion_speed + float(i) * 0.6) * distortion_amplitude;
			//ellipse_dist += sin(ellipse_config.x + TIME) * 0.05;
			dist = smooth_union(dist, sdf_cloud_piece(uv, ellipse_config.xy, ellipse_config.zw, variation_random + float(i) * 0.6), merge_k);
			//dist = union(dist, ellipse_dist);
		}
	}

	//dist = smooth_subtract(dist, subtract_ellipse_dist, merge_k);
	//dist = subtract(dist, distance_to_depth);

	//dist = subtract(dist, texture(density_noise, UV).r

	// Show outline where intersecting depth.
	float distance_to_depth = sdf_circle(uv, 0.65);
	float normalized_distance_to_depth = remap(distance_to_depth, 0.0, 0.1, 0.0, 1.0);

	float dist_unit = remap(dist, -range, range, 0.0, 1.0);
	if (debug) {
		COLOR = texture(gradient_debug, vec2(dist_unit, 0.5));
	}
	else
	{
		vec4 gradient_color = texture(gradient, vec2(dist_unit, 0.5));
		vec4 gradient_color2 = texture(gradient_backup, vec2(dist_unit, 0.5));
		float noise_amount = noise_strength * noise(floor((UV + variation_random) * noise_scale));
		COLOR.rgb = mix(mix(gradient_color, gradient_color2, normalized_distance_to_depth).rgb, noise_color, noise_amount);
		COLOR.a *= gradient_color.a;
	}
}