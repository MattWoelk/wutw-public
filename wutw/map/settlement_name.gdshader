shader_type canvas_item;

uniform sampler2D overlay_tex : repeat_enable;
uniform float overlay_scale = 2.0;
uniform float width = 231.0;
uniform vec3 color_add : source_color = vec3(0.33);
uniform float power = 3.5;
uniform float reveal_progress: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float reveal_margin: hint_range(0.0, 1.0, 0.01) = 0.1;

varying vec2 vertex_pos;

void vertex() {
	vertex_pos = VERTEX;
}

void fragment() {
	vec2 real_uv = vertex_pos / width;
	if (COLOR.r > 0.2) {
		COLOR.rgb = pow(texture(overlay_tex, real_uv / overlay_scale).rgb, vec3(power)) + color_add;
	}
	
	float threshold = reveal_progress * (1.0 + reveal_margin);
	COLOR.a *= smoothstep(threshold, threshold - reveal_margin, real_uv.x);
}
