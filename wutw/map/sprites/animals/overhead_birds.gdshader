shader_type canvas_item;
render_mode blend_mix;
uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;
uniform float debug_frame: hint_range(-0.01, 2.0, 0.01) = -0.01;

varying float frame_num;

#include "res://visuals/shaders/utils.gdshaderinc"

void vertex() {
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	VERTEX.xy /= vec2(h_frames, v_frames);
	frame_num = debug_frame >= 0.0 ? debug_frame : INSTANCE_CUSTOM.z;
}

void fragment() {
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);

	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float frame_num_scaled = frame_num * float(particle_total_frames);

	float frame1 = mod(floor(frame_num_scaled), particle_total_frames);
	float frame2 = mod(ceil(frame_num_scaled), particle_total_frames);
	float frame_alpha = fract(frame_num_scaled);

	vec2 uv = UV / vec2(h_frames, v_frames);

	float blurAmount = smoothstep(0.7, 1.0, frame_alpha);

	vec2 uv1 = uv + vec2(mod(frame1, h_frames) / h_frames, floor((frame1 + 0.5) / h_frames) / v_frames);
	vec2 uv2 = uv + vec2(mod(frame2, h_frames) / h_frames, floor((frame2 + 0.5) / h_frames) / v_frames);

	vec4 sample1 = texture(TEXTURE, uv1);
	vec4 sample2 = texture(TEXTURE, uv2);
	COLOR = mix(sample1, sample2, frame_alpha);
	COLOR.a = smoothstep(0.4, 0.6, COLOR.a);
}