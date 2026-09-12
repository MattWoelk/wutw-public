shader_type canvas_item;

uniform float min_v = 0.5;
uniform float margin = 0.1;

void fragment() {
	COLOR.a *= smoothstep(min_v * (1.0 - margin), min_v * (1.0 + margin), UV.y);
}
