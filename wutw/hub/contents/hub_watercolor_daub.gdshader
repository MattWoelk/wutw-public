shader_type canvas_item;

uniform int daub_frames_h = 3;
uniform int daub_frames_v = 3;
uniform vec3 daub_color: source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 daub_color2: source_color = vec3(0.0, 1.0, 0.0);
uniform float daub_alpha = 1.0;
uniform sampler2D color_noise: repeat_enable;

group_uniforms detail_noise;
uniform float noise_scale : hint_range(1, 500) = 200;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;
uniform vec3 noise_color : source_color = vec3(0.0);

#include "res://visuals/shaders/noise.gdshaderinc"

varying float random_seed;

void vertex() {
	random_seed = float(INSTANCE_ID);
}

void fragment() {
	int frame_index = int(9.0 * value_noise_1_1(random_seed)) % 3; // only use the first 3 frames
	int frame_x = frame_index % daub_frames_h;
	int frame_y = frame_index / daub_frames_h;
	vec2 frame_offset = vec2(float(frame_x) / float(daub_frames_h),
							float(frame_y) / float(daub_frames_v));
	vec2 frame_uv = UV / vec2(float(daub_frames_h), float(daub_frames_v));
	float alpha = texture(TEXTURE, frame_offset + frame_uv).r;
	vec2 noise_uv = UV + value_noise_1_1(random_seed);
	COLOR = vec4(mix(daub_color, daub_color2, texture(color_noise, noise_uv).r), clamp(alpha * daub_alpha, 0.0, 1.0));
	
	float noise_amount = noise_strength * value_noise_2_1_smooth(random_seed + UV * noise_scale, noise_smoothness);
	COLOR.rgb = mix(COLOR.rgb, noise_color, noise_amount);
}
