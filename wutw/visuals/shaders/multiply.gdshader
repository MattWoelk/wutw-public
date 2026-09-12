shader_type canvas_item;
render_mode blend_mul;

void fragment() {
	COLOR.rgb = mix(vec3(1), COLOR.rgb, COLOR.a);
}
