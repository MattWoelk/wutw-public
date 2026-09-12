shader_type canvas_item;

group_uniforms dynamic_state;
uniform vec4 global_rect;
uniform sampler2D landmass_sdf : filter_linear_mipmap_anisotropic;
uniform sampler2D shard_tex : filter_linear_mipmap_anisotropic;
uniform float landmass_threshold : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float landmass_edge_distance : hint_range(0.0001, 0.1, 0.001) = 0.001;

group_uniforms shapes;
const int NUM_ELLIPSES = 8;
uniform vec4[NUM_ELLIPSES] ellipses;
uniform vec4[NUM_ELLIPSES] ellipses2;

group_uniforms grid;
uniform vec2 global_offset;
uniform float global_scale = 3.0;
uniform vec2 global_spacing = vec2(0.7, 0.4);
uniform float x_randomization = 0.0;
uniform float y_randomization = 0.2;
uniform float global_speed : hint_range(0.001, .2) = 0.02;

group_uniforms smoothness;
uniform float merge_k : hint_range(0.001, 0.1, 0.001) = 0.1;

group_uniforms distortion;
uniform float distortion_amplitude : hint_range(0.0001, 0.1) = 0.01;
uniform float distortion_speed : hint_range(0.001, 10) = 1.0;

group_uniforms color;
uniform float range : hint_range(0.001, 10, 0.001) = 0.5;
uniform sampler2D gradient : filter_linear_mipmap_anisotropic;

group_uniforms detail_noise;
uniform float noise_scale : hint_range(1, 500) = 200;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;
uniform vec3 noise_color : source_color = vec3(0.0);

group_uniforms randomization;
uniform float variation_random : hint_range(0.0, 1.0) = 0.0;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

/////////////  NOISE  /////////////

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

/////////////  MAIN  /////////////

float sdf_cloud(vec2 p, vec2 id) {
	// Randomization.
	id += variation_random;
	p += sin(hash(id + 456.243) * TAU + TIME * distortion_speed / 5.0) * 0.02;
	p.y += remap(hash(id + 2.351), 0., 1., .5, -.5) * y_randomization;
	p.x += remap(hash(id + 122.513), 0., 1., .5, -.5) * x_randomization;
	float time = TIME;
	time += hash(id + 958.826) * TAU;
	float set_random = hash(id + 958.826);

	float dist = 1.0;
	for (int i = 0; i < NUM_ELLIPSES; ++i) {
		vec4 ellipse_config = (set_random < 0.5 ? ellipses : ellipses2)[i];
		if (ellipse_config.z > 0.0) {
			ellipse_config.zw *= 1.0 + 10.0*sin(variation_random * TAU + TIME * distortion_speed + float(i) * 0.6) * distortion_amplitude;
			float ellipse_dist = sdf_ellipse(translate(p, ellipse_config.xy - vec2(0.5,0.5)), ellipse_config.zw);
			dist = smooth_union(dist, ellipse_dist, merge_k);
		}
	}
	return dist + hash(id) * 0.01;
}

float sdf_repeated_cloud(vec2 p, vec2 s) {
	vec2 id = round(p / s);
	vec2 o = sign(p - s * id); // neighbor offset direction

	float d = 1e20;
	for (int j = 0; j < 2; j++ ) {
		for (int i = 0; i < 2; i++ ) {
			vec2 rid = id + vec2(float(i), float(j)) * o;
			vec2 r = p - s * rid;
			d = smooth_union(d, sdf_cloud(r, rid), merge_k);
		}
	}

	return d;
}

void fragment() {
	vec2 uv = UV - vec2(0.5, 0.5) + global_offset;

	float dist = sdf_repeated_cloud(uv * global_scale + vec2(TIME * global_speed, 0.0), global_spacing);
	float dist_unit = remap(dist, -range, range, 0.0, 1.0);
	vec4 gradient_color = texture(gradient, vec2(dist_unit, 0.5));
	float noise_amount = noise_strength * noise(floor((UV + variation_random) * noise_scale));
	COLOR.rgb = mix(gradient_color.rgb, noise_color, noise_amount);
	COLOR.a *= gradient_color.a;

	float global_u = remap(UV.x, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_v = remap(UV.y, 0.0, 1.0, global_rect.y, global_rect.w);
	float distance_to_landmass = texture(landmass_sdf, vec2(global_u, global_v)).r;
	float alpha = smoothstep(landmass_threshold + landmass_edge_distance, landmass_threshold, distance_to_landmass);
	COLOR.a *= alpha;

	// Shape alpha.
	vec4 shard_sample = texture(shard_tex, vec2(global_u, global_v));
	float dist_from_top_raw = shard_sample.g;
	float min_dist_to_area = shard_sample.a;
	float dist_y = dist_from_top_raw * 255.0;
	float shard_base_alpha = smoothstep(1.0 - 0.04, 1.0, min_dist_to_area);
	shard_base_alpha = (smoothstep(1.0 - 0.04, 1.0, min_dist_to_area)
					  * smoothstep(40.0, 10.0, dist_y));
	COLOR.a = 1.0 - shard_base_alpha;
}
