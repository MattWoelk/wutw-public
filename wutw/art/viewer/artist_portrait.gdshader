shader_type canvas_item;

uniform float border_size: hint_range(0.0, 0.1, 0.001) = 0.05;
uniform vec4 border_color: source_color = vec4(0, 0, 0, 1);

void fragment() {
	float ratio = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	float h_border_size = border_size;
	float v_border_size = border_size * ratio;
	if (UV.x < h_border_size || UV.y < v_border_size ||
			UV.x >= (1.0 - h_border_size) || UV.y >= (1.0 - v_border_size)) {
		COLOR *= border_color;
	}
}
