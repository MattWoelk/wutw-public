shader_type canvas_item;

uniform sampler2D noise_tex: repeat_enable, filter_linear_mipmap;
uniform float noise_scale : hint_range(1.0, 10.0) = 1.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 1.0;

#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	vec2 square_uv = UV;
	square_uv.y /= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	COLOR.rgb = texture(noise_tex, square_uv * noise_scale).rgb;
	COLOR.a *= noise_strength;
}
