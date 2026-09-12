shader_type canvas_item;

uniform sampler2D frame: source_color;
uniform sampler2D frame_tall: source_color;
uniform sampler2D frame_wide: source_color;
uniform sampler2D bg: source_color;
uniform vec4 bg_color: source_color;
uniform vec3 undiscovered_color: source_color = vec3(0.804, 0.894, 1.0);
uniform float hover_intensity = 0.2;
uniform float undiscovered_power = 6.0;
group_uniforms dynamic;
uniform float hovered: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float selected: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform bool is_tall = false;
uniform bool is_wide = false;
uniform bool discovered = true;

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
	vec4 frame_sample = is_tall ? texture(frame_tall, UV) : (is_wide ? texture(frame_wide, UV) : texture(frame, UV));
	vec4 bg_sample = texture(bg, UV);
	if (!discovered) {
		COLOR.r = pow(bg_sample.r, undiscovered_power);
		COLOR.g = pow(bg_sample.g, undiscovered_power);
		COLOR.b = pow(bg_sample.b, undiscovered_power);
		COLOR.rgb *= undiscovered_color;
	}
	vec4 content = alpha_blend(COLOR, bg_sample * bg_color);
	COLOR.rgb = content.rgb * mix(vec3(1.0), frame_sample.rgb, mix(0.5, 1.5, selected));
	COLOR.rgb *= (1.0 + hover_intensity * max(selected, hovered));
	COLOR.a = frame_sample.a;
}
