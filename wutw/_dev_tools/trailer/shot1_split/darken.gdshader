shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	vec3 base = texture(screen_texture, SCREEN_UV).rgb;
	COLOR.rgb = min(COLOR.rgb, base);
}
