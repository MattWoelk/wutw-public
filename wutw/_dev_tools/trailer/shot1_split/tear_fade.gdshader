shader_type canvas_item;

uniform float progress: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR.a *= mix(0.0, 1.5, progress) - distance(vec2(0.5, 0.5), UV) * 0.5;
}
