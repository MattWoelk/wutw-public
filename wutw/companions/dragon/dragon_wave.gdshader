shader_type canvas_item;

uniform sampler2D gradient: repeat_disable, filter_linear_mipmap_anisotropic;
uniform sampler2D noise: repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec2 direction = vec2(0.0, 1.0);
uniform float scale: hint_range(0.01, 10.0, 0.01) = 1.0;
uniform float speed: hint_range(0.0, 0.5, 0.01) = 0.5;
uniform float strength: hint_range(0.0, 2.0, 0.01) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	float noise_sample = texture(noise, UV * scale + vec2(TIME * speed, 0)).r;
	float impact = 1.0 - texture(gradient, UV).r;
	vec2 uv = UV + (direction * noise_sample * impact * strength);
	COLOR = texture(TEXTURE, uv);
}
