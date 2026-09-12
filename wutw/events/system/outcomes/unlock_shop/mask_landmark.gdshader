shader_type canvas_item;

uniform sampler2D mask: filter_linear_mipmap, repeat_disable;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= texture(mask, UV).a;
}
