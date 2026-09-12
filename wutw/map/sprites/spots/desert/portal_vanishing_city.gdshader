shader_type canvas_item;

uniform sampler2D city: filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D distort_noise: filter_linear_mipmap_anisotropic, repeat_enable;
uniform float min_opacity: hint_range(0.0, 1.0, 0.01) = 0.15;
uniform float max_opacity: hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float fade_speed: hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float distort_speed: hint_range(0.0, .2, 0.001) = 1.0;
uniform float distort_amount: hint_range(0.0, 4.0, 0.01) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u);
}

void fragment() {
	float mask_opacity = texture(TEXTURE, UV).a;
	float opacity = mask_opacity * mix(min_opacity, max_opacity, noise(TIME * fade_speed));
	
	float distort_sample = texture(distort_noise, UV + 3.0 * vec2(TIME * distort_speed, TIME * distort_speed / 2.0)).r;
	float distort_influence = clamp(distort_sample * (1.2 - mask_opacity), 0, 1);
	vec2 uv_offset = vec2(distort_amount * remap(distort_influence, 0, 1, -0.5, 0.5), 0);
	vec3 city_color = texture(city, remap2(UV, 0.0, 1.0, -distort_amount * distort_influence, 1.0 + distort_amount * distort_influence)).rgb;
	
	COLOR = vec4(city_color, opacity);
}