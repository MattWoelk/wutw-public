shader_type canvas_item;

uniform sampler2D gradient: repeat_disable;
instance uniform float factor : hint_range(0.0, 10.0, 0.1) = 0;
uniform float power : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float speed : hint_range(0.1, 10.0, 0.1) = -0.5;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	vec4 gradient_sample = texture(gradient, vec2(UV.x, fract(UV.y + TIME * speed)));

	vec3 hsv = rgb2hsv(COLOR.rgb);
	hsv.b = rgb2hsv(texture(TEXTURE, UV).rgb).b;
	vec3 gradient_mult = hsv2rgb(hsv);

	COLOR.r += pow(gradient_mult.r * gradient_sample.a * factor, power);
	COLOR.g += pow(gradient_mult.g * gradient_sample.a * factor, power);
	COLOR.b += pow(gradient_mult.b * gradient_sample.a * factor, power);
}
