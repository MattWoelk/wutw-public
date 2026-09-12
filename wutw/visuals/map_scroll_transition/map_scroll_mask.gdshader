shader_type canvas_item;

uniform float left: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float right: hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	COLOR.a *= UV.x < left ? 0.0 : (UV.x > right ? 0.0 : 1.0);
}
