shader_type canvas_item;

instance uniform float progress: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec3 color: source_color = vec3(0.18, 0.059, 0.024);
uniform float edge: hint_range(0.0, 0.5, 0.01) = 0.1;

void fragment() {
	COLOR.a *= 1.0 - smoothstep(progress - edge, progress, (1.0 - COLOR.r));
	COLOR.rgb = color;
}
