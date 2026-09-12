shader_type canvas_item;

uniform sampler2D base_tex: repeat_disable, filter_linear_mipmap;
uniform sampler2D glow_tex: repeat_disable, filter_linear_mipmap;
uniform vec3 positive_color : source_color = vec3(0.3, 1.0, 0.0);
uniform vec3 negative_color : source_color = vec3(1.0, 0.0, 0.0);
uniform float min_width : hint_range(0, 10) = 3.0;
uniform float max_width : hint_range(0, 10) = 10.0;
uniform float animation_speed : hint_range(0, 10) = 2.5; // Min-to-max animation speed
uniform bool enable_outline = false;
uniform bool is_negative = false;

#include "res://visuals/shaders/utils.gdshaderinc"

float get_current_width() {
	return float(enable_outline) * mix(min_width, max_width, (1.0 + sin(TIME*animation_speed)));
}

void fragment() {
	vec4 color = texture(base_tex, UV);
	COLOR.a *= color.a;  // Double-apply alpha, intentionally.

	if (enable_outline) {
		vec4 glow_sample = texture(glow_tex, UV);
		float glow_alpha = glow_sample.a * glow_sample.r * get_current_width();
		vec3 glow_color = is_negative ? negative_color : positive_color;
		color = alpha_blend(color, vec4(glow_color.rgb, glow_alpha));
	}
	COLOR *= color;
}