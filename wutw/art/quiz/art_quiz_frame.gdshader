shader_type canvas_item;

void fragment() {
	float change_x = dFdx(UV.x) * 2.0;
    float change_y = dFdy(UV.y) * 2.0;
	if (UV.x < change_x || UV.y < change_y || UV.x > (1.0 - change_x) || UV.y > (1.0 - change_y)) {
		COLOR.rgb = vec3(0);
	}
}
