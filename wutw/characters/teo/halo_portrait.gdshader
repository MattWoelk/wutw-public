shader_type canvas_item;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

uniform float speed : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float offset : hint_range(0.0, 1.0, 0.01) = 0.13;
uniform vec2 center = vec2(0.5, 0.5);
uniform float scale : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform sampler2D gradient : repeat_enable, filter_linear_mipmap_anisotropic;

void fragment() {
	float dist = -sdf_circle(UV - center, scale);
	vec4 color = texture(gradient, vec2(dist + TIME * speed, 0.5));
	vec4 color2 = texture(gradient, vec2(dist + offset + TIME * speed, 0.5));
	vec4 glow = mix(color, color2, 0.5);
	glow.a *= dist;
	COLOR = alpha_blend(COLOR, glow);
}
