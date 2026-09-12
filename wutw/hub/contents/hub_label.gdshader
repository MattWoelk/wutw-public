shader_type canvas_item;

uniform sampler2D tex: repeat_disable, filter_linear_mipmap;
uniform vec4 fill_color: source_color;
uniform vec4 border_color: source_color;

group_uniforms detail_noise;
uniform vec2 noise_scale = vec2(60, 100);
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;
uniform vec3 noise_color : source_color = vec3(0.0);

#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	vec4 sample = texture(TEXTURE, UV);
	vec4 color = fill_color;

	float noise_amount = noise_strength * value_noise_2_1_smooth(UV * noise_scale, noise_smoothness);
	color.rgb = mix(color.rgb, noise_color, clamp(pow(2.0, noise_amount) - 2.0, 0.0, 1.0));

	color = mix(color, border_color, sample.r);

	color.a = sample.a;

	COLOR.rgb = color.rgb;
	COLOR.a *= color.a;
}
