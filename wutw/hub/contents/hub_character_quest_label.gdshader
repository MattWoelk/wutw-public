shader_type canvas_item;

#include "res://visuals/shaders/utils.gdshaderinc"

instance uniform bool is_completed = false;

void fragment() {
	if (is_completed) {
		vec3 hsv = rgb2hsv(COLOR.rgb);
		hsv.y = 0.0;
		COLOR.rgb = hsv2rgb(hsv);
		COLOR.a *= 0.8;
	}
}
