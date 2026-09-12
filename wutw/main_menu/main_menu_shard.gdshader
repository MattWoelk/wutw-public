shader_type canvas_item;

uniform sampler2D gradient: repeat_disable, filter_linear;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	float horizon_fade = texture(gradient, vec2(0, SCREEN_UV.y)).a;
	float local_v = remap(UV.y, REGION_RECT.y, REGION_RECT.y + REGION_RECT.w, 0, 1);
	float bottom_fade = remap(local_v, 0.8, 0.3, 0.0, 1.0);
	COLOR.a *= horizon_fade * bottom_fade;
}
