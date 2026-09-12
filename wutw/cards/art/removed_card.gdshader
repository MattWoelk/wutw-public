shader_type canvas_item;
uniform vec3 background_color: source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D mask: repeat_disable, filter_linear_mipmap;
uniform vec2 separation = vec2(0.04, 0.03);
uniform float progress: hint_range(0.0, 1.0) = 0.5;

#include "res://visuals/shaders/utils.gdshaderinc"

float get_intensity(vec3 color) {
	return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

void fragment() {
	vec2 src_uv_left = UV + separation * progress;
	vec2 src_uv_right = UV - separation * progress;

	vec4 left_mask = texture(mask, src_uv_left);
	vec4 right_mask = texture(mask, src_uv_right);
	float mask_at_left_src = left_mask.r;
	float mask_at_right_src = right_mask.r;

	bool is_valid_left = mask_at_left_src > 0.5 && src_uv_left.x <= 1.0;
	bool is_valid_right = mask_at_right_src < 0.5 && src_uv_right.x >= 0.0;

	if (is_valid_left) {
		COLOR = texture(TEXTURE, src_uv_left) - left_mask.b * progress;
		COLOR.a *= mask_at_left_src;
		COLOR.a *= mix(1.0, 1.0 - left_mask.g, progress);
	} else if (is_valid_right) {
		COLOR = texture(TEXTURE, src_uv_right) - right_mask.b * progress;
		COLOR.a *= 1.0 - mask_at_right_src;
		COLOR.a *= mix(1.0, 1.0 - right_mask.g, progress);
	} else {
		COLOR = vec4(0.0);
	}
	
	vec3 hsv = rgb2hsv(background_color);
	hsv.b = get_intensity(COLOR.rgb);
	COLOR.rgb = mix(COLOR.rgb, hsv2rgb(hsv), progress);
}
