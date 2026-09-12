shader_type canvas_item;

uniform float noise_scale : hint_range(0.01, 100) = 0.5;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec3 noise_color : source_color = vec3(0.0);

#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	float noise = value_noise_2_1(floor(UV * noise_scale));
	float brightness = max(max(original_color.r, original_color.g), original_color.b);
	float dist_from_center = 1.0 - distance(vec2(0.5, 0.5), UV);
	vec3 mixed = mix(original_color.rgb, noise_color, noise * noise_strength * brightness * dist_from_center);
	COLOR /= texture(TEXTURE, UV);
	COLOR.rgb *= mixed.rgb;
	COLOR.a *= mix(original_color.a, 0.0, (1.0 - noise) * noise_strength);
}
