shader_type canvas_item;

uniform sampler2D water_noise;
uniform sampler2D water_noise2;
uniform vec2 water_noise_uv_scale = vec2(1.0, 1.0);
uniform vec4 shade_color: source_color;
uniform float anim_speed = 1.3;

uniform sampler3D macro_water_noise: repeat_enable;
uniform float macro_anim_speed = 0.8;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	float shade_amount = 1.0 - COLOR.r;

	vec3 color_1 = texture(water_noise, UV * water_noise_uv_scale).rgb;
	vec3 color_2 = texture(water_noise2, UV * water_noise_uv_scale).rgb;
	float anim_phase = remap(sin(TIME * anim_speed), -1, 1, 0, 1);
	vec3 color_macro = texture(macro_water_noise, vec3(UV * water_noise_uv_scale, TIME * macro_anim_speed)).rgb;
	COLOR.rgb = mix(mix(color_1, color_2, anim_phase), color_macro, 0.8);

	COLOR.rgb= mix(COLOR.rgb, shade_color.rgb, shade_amount * shade_color.a);
}
