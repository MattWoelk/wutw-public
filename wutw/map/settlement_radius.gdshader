shader_type canvas_item;

uniform float highlight_progress : hint_range(0.0, 1.0) = 0.00;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // white
uniform float size : hint_range(10.0, 1000.0) = 300.0;
uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float thickness : hint_range(0.0, 1.0) = 0.02;
uniform float thickness_highlighted : hint_range(0.0, 1.0) = 0.02;
uniform float smoothness : hint_range(0.0, 1.0) = 0.01;
uniform float noise_scale : hint_range(0.01, 1000) = 0.5;
uniform float noise_strength : hint_range(0.0, 2.0) = 0.25;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 0.25;

group_uniforms landmass_clip;
uniform vec4 global_rect;
uniform sampler2D landmass_sdf : filter_linear_mipmap_anisotropic;
uniform float landmass_threshold : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float landmass_edge_distance : hint_range(0.0001, 0.1, 0.001) = 0.001;

const float DEFAULT_SIZE = 200.0;

#include "res://visuals/shaders/utils.gdshaderinc"

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

void fragment() {
	vec2 uv = UV * 2.0 - 1.0; // Convert UV from [0,1] to [-1,1]
	float dist = length(uv);  // Distance from center

	float angle = atan(UV.y - 0.5, UV.x - 0.5) / TAU + 0.5;
	float actual_thickness = mix(thickness, thickness_highlighted, smoothstep(angle - 0.05, angle, highlight_progress * 1.05 - 0.05));
	actual_thickness *= sqrt(DEFAULT_SIZE / size);
	float edge_inner = radius - actual_thickness;
	float edge_outer = radius;
	float alpha = smoothstep(edge_outer, edge_outer - smoothness, dist)
			    * smoothstep(edge_inner, edge_inner + smoothness, dist);

	float noise = noise(floor(UV * noise_scale));
	COLOR.rgb *= color.rgb;
	COLOR.a *= clamp(color.a * alpha * (1.0 - noise * noise_strength), 0.0, 1.0);

	float global_u = remap(UV.x, 0.0, 1.0, global_rect.x, global_rect.z);
	float global_v = remap(UV.y, 0.0, 1.0, global_rect.y, global_rect.w);
	float distance_to_landmass = texture(landmass_sdf, vec2(global_u, global_v)).r;
	float alpha_landmass = smoothstep(landmass_threshold + landmass_edge_distance, landmass_threshold, distance_to_landmass);
	COLOR.a *= 1.0 - alpha_landmass;
}
