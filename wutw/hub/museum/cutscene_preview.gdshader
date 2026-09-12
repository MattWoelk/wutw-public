shader_type canvas_item;

uniform sampler2D mask: repeat_disable;

void fragment() {
	COLOR.a *= texture(mask, UV).a;
}
