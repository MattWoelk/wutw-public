shader_type canvas_item;

uniform sampler2D main_noise: repeat_enable;
uniform sampler2D detail_noise: repeat_enable;
uniform float detail_noise_scale : hint_range(.01, 100) = 1.0;
uniform float shine_noise_scale : hint_range(.01, 1.0) = 1.0;
uniform vec2 shine_amount = vec2(-0.5, 0.5);
uniform vec4 shine_color: source_color;
uniform vec2 size = vec2(157, 99);

#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/utils.gdshaderinc"

varying vec2 pixel_pos;

void vertex() {
	pixel_pos = VERTEX;
}

void fragment() {
	vec2 box_uv = pixel_pos / size;
	box_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	float main_sample = texture(main_noise, box_uv).r;
	float detail_sample = texture(detail_noise, box_uv * detail_noise_scale).r;
	vec4 shine = shine_color;
	shine.a *= main_sample * detail_sample;

	vec3 hsv = rgb2hsv(shine.rgb);
	hsv.y += remap(detail_sample, 0, 1, shine_amount.x, shine_amount.y);
	hsv.z += remap(detail_sample, 0, 1, shine_amount.x, shine_amount.y);
	shine.rgb = hsv2rgb(hsv);
	
	COLOR.rgb += shine.rgb * shine.a;
}
