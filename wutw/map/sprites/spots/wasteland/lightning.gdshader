shader_type canvas_item;

uniform sampler2D spritesheet;
uniform sampler2D anim_gradient;
uniform int frames_h = 2;
uniform int frames_v = 2;
uniform float anim_speed = 4.0;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

varying vec4 custom_data;

void vertex() {
	custom_data = INSTANCE_CUSTOM;
}

vec4 sample_tex(sampler2D tex, vec2 full_uv, float random_seed) {
	float random = value_noise_1_1(random_seed);
	int frame_index = int(random * float(frames_h * frames_v));
	int frame_x = frame_index % frames_h;
	int frame_y = frame_index / frames_h;
	vec2 frame_offset = vec2(float(frame_x) / float(frames_h),
							float(frame_y) / float(frames_v));
	vec2 frame_uv = full_uv / vec2(float(frames_h), float(frames_v));
	return texture(tex, frame_offset + frame_uv);
}
void fragment() {
	float frame_random = custom_data.b;
	float lifetime = custom_data.g;
	
	vec4 color = sample_tex(spritesheet, UV, custom_data.b);
	COLOR.rgb *= color.rgb;
	COLOR.a *= color.a;
	
	float t = remap(lifetime, 1.0 - 1.0 / anim_speed, 1, 0, 1);
	COLOR.a *= texture(anim_gradient, vec2(t, UV.y)).r;
}

