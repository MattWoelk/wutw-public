shader_type canvas_item;

uniform sampler2D mask: source_color, filter_linear_mipmap_anisotropic;

void fragment() {
	COLOR.a *= texture(mask, UV).a;
}
