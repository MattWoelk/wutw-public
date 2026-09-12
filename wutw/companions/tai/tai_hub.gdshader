shader_type canvas_item;

uniform sampler2D mask: repeat_disable, filter_linear_mipmap_anisotropic;
instance uniform float depth: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR.a *= texture(mask, UV + vec2(0, depth)).a;
}
