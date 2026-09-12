shader_type canvas_item;

uniform sampler2D screen_texture: hint_screen_texture;
uniform vec2 offset = vec2(0.0, 0.0);
uniform vec2 scale = vec2(1.0, 1.0);
uniform vec2 brighten_threshold = vec2(0.4, 0.5);
uniform float brighten_amount = 0.4;
uniform float brightening_factor = 0.4;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	vec4 top = texture(TEXTURE, UV.yx * scale + offset);
	vec4 bottom = texture(screen_texture, SCREEN_UV);

	vec3 brightening = mix(bottom.rgb, top.rgb * brightening_factor, COLOR.a * brighten_amount);
	vec3 darkening = mix(bottom.rgb, bottom.rgb * top.rgb, COLOR.a);
	COLOR.rgb = mix(darkening, brightening, smoothstep(brighten_threshold.y, brighten_threshold.x, darkest(bottom.rgb)));
}
