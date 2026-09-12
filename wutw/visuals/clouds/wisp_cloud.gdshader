shader_type canvas_item;

uniform sampler2D water_noise;
uniform sampler2D water_noise2;
uniform vec2 water_noise_uv_scale = vec2(1.0, 1.0);
uniform float anim_speed = 1.3;
uniform sampler3D macro_water_noise: repeat_enable;
uniform float macro_anim_speed = 0.8;

uniform float alpha_multiplier = 1.0;
uniform vec2 distance_cutoff = vec2(-50.0, 50.0); // px

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
    vec2 at = screen_uv_to_sdf(SCREEN_UV);
	float sdf_mask = remap(texture_sdf(at), distance_cutoff.x, distance_cutoff.y, 0, 1);
	COLOR.a *= sdf_mask;
	if (COLOR.a <= 0.0) {
		discard;
	} else {
		vec2 square_uv = UV;
		vec2 texture_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
		square_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
		float color_1 = texture(water_noise, square_uv * water_noise_uv_scale).r;
		float color_2 = texture(water_noise2, square_uv * water_noise_uv_scale).r;
		float anim_phase = remap(sin(TIME * anim_speed), -1, 1, 0, 1);
		float color_macro = texture(macro_water_noise, vec3(square_uv * water_noise_uv_scale, TIME * macro_anim_speed)).r;
		COLOR.a *= alpha_multiplier * mix(mix(color_1, color_2, anim_phase), color_macro, 0.8);
	}
}
