shader_type canvas_item;

uniform vec2 position = vec2(0.2, 0.3);
uniform vec2 size = vec2(0.4, 0.4);
uniform vec2 range = vec2(0.5, 0.6);

#include "res://visuals/shaders/sdf.gdshaderinc"

void fragment() {
	vec2 coord = UV * vec2(1920.0, 1080.0);
	COLOR.a *= 1.0 - smoothstep(range.x, range.y, sdf_box(translate(coord, position + size / 2.0), size / 2.0));
}
