shader_type canvas_item;
render_mode blend_sub;

group_uniforms config;
uniform float margin = 0;  // px
uniform float spacing: hint_range(0.1, 1.0, 0.01) = 0.5;
uniform vec4 positive_color: source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 negative_color: source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 full_color: source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float blend: hint_range(0.0, 0.4, 0.01) = 0.01;
uniform float damage_blend: hint_range(0.0, 0.4, 0.01) = 0.01;
uniform float roundness: hint_range(0.0, 3.0, 0.01) = 1.;
uniform float progress_margin: hint_range(-0.4, 0.4, 0.01) = 0.01;
uniform float progress_scale: hint_range(.1, 2.0, 0.01) = 1.0;
uniform bool is_negative = false;

group_uniforms constants;
uniform sampler2D daub_tex: repeat_enable;
uniform int daub_frames_h = 3;
uniform int daub_frames_v = 3;

group_uniforms dynamic;
uniform vec2 size = vec2(100, 100);  // px
uniform float progress: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float damage_progress: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float full_anim_progress: hint_range(0.0, 1.0, 0.01) = 0.0;

#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/utils.gdshaderinc"

vec4 draw_daub(int daub_index, vec2 uv, vec4 color) {
	int frame_index = int(float(daub_frames_h * daub_frames_h + 1) * value_noise_1_1(float(daub_index)));
	int frame_x = frame_index % daub_frames_h;
	int frame_y = frame_index / daub_frames_h;
	vec2 frame_offset = vec2(float(frame_x) / float(daub_frames_h),
							float(frame_y) / float(daub_frames_v));
	vec2 frame_uv = uv / vec2(float(daub_frames_h), float(daub_frames_v));
	float tex_alpha = texture(daub_tex, frame_offset + frame_uv).r;
	return vec4(color.rgb, clamp(tex_alpha * color.a, 0.0, 1.0));
}

void fragment() {
	vec2 local_pos = UV * size;
	float radius = size.y + margin;

	int center_i = int(round(local_pos.x / size.x));
	int tiles = int(round(1.0 / spacing));
	float tile_interval = (radius * spacing) / size.y;

	vec4 accum = vec4(0);
	for (int i = -tiles; i < tiles - 1; ++i) {
		float offset = float(i) * tile_interval;
		vec2 tile_uv = vec2(local_pos.x / size.y + offset, remap(local_pos.y, -margin, radius, 0, 1));
		tile_uv.x = mod(tile_uv.x, 1.0);
		// HACK: Not quite right, and introduces cut-off tiles, but close enough at usage scale.
		int global_daub_index = i + int(floor(local_pos.x / radius));
		vec4 color = is_negative ? negative_color : positive_color;
		if (damage_progress > 0.0) {
			float negative_alpha = 1.0 - smoothstep(UV.x, UV.x + damage_blend, progress_margin + (progress - damage_progress) * progress_scale);
			color = mix(color, negative_color, negative_alpha);
		}
		color = mix(color, full_color, full_anim_progress);
		vec4 cur_daub = draw_daub(global_daub_index, tile_uv, color);
		float progress_alpha = smoothstep(UV.x, UV.x + blend, progress_margin + progress * progress_scale);
		float dist_from_center = pow(clamp(1.0 - distance(tile_uv, vec2(0.5, 0.5)) / 0.5, 0, 1), roundness);
		if (progress_alpha < 1.0) {
			cur_daub.a *= remap(progress_alpha, 0, 1, dist_from_center - 1.0, 1);
		}
		accum = alpha_blend(accum, cur_daub);
	}
	COLOR *= accum;
}
