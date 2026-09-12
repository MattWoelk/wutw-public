shader_type canvas_item;
render_mode blend_add;

void fragment() {
	COLOR.rgb *= COLOR.a;
}
