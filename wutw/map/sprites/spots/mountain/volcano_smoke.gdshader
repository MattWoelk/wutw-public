shader_type canvas_item;

uniform sampler2D spritesheet;
uniform int daub_frames_h = 3;
uniform int daub_frames_v = 3;
uniform vec4 daub_color_min: source_color = vec4(1);
uniform vec4 daub_color_max: source_color = vec4(1);
uniform float opacity_boost = 1.5;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

varying vec4 custom_data;

void vertex() {
	custom_data = INSTANCE_CUSTOM;
}

vec4 fragment_daub(sampler2D tex, vec2 full_uv, float random_seed) {
	float random = value_noise_1_1(random_seed);
	int frame_index = int(random * float(daub_frames_h * daub_frames_v));
	// HACK: Frames 4 and 5 looks bad in this context.
	if (frame_index == 3 || frame_index == 4) frame_index *= 2;
	int frame_x = frame_index % daub_frames_h;
	int frame_y = frame_index / daub_frames_h;
	vec2 frame_offset = vec2(float(frame_x) / float(daub_frames_h),
							float(frame_y) / float(daub_frames_v));
	vec2 frame_uv = full_uv / vec2(float(daub_frames_h), float(daub_frames_v));
	float alpha = texture(tex, frame_offset + frame_uv).r;
	
	float color_random = value_noise_1_1(random_seed + 10.0);
	vec4 daub_color = mix(daub_color_min, daub_color_max, color_random);
	
	return vec4(daub_color.rgb, alpha * daub_color.a);
}
void fragment() {
	vec4 color = fragment_daub(spritesheet, UV, custom_data.a);
	COLOR.rgb *= color.rgb;
	COLOR.a *= clamp(pow(color.a, 3.0) * opacity_boost * (1.0 + length(UV - vec2(0.5))), 0, 1);
}
