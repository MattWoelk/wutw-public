shader_type canvas_item;

uniform sampler2D bokashi_texture: repeat_enable;
uniform float bokashi_darkening = 1.0;
uniform float overlay_offset_vertical = 0.0;
uniform float overlay_multiplier_u: hint_range(0.01, 10.0) = 1.0;
uniform float overlay_multiplier_v: hint_range(0.01, 10.0) = 1.0;

void fragment() {
	vec4 a = texture(TEXTURE, UV);
	vec2 overlay_uv = vec2(SCREEN_UV.x * overlay_multiplier_u, SCREEN_UV.y * overlay_multiplier_v + overlay_offset_vertical);
	vec4 b = texture(bokashi_texture, overlay_uv) * bokashi_darkening;

	vec3 result;
	for (int i = 0; i < 3; ++i) {
		if (a[i] < 0.5) {
	    	result[i] = 2.0 * a[i] * b[i];
		} else {
		    result[i] = 1.0 - 2.0 * (1.0 - a[i]) * (1.0 - b[i]);
		}
	}
	COLOR.rgb = result.rgb;
}
