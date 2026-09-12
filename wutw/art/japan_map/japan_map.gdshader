shader_type canvas_item;

uniform vec4 color: source_color = vec4(1.0);
uniform sampler2D tex: source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec2 scale = vec2(1.0);

void fragment() {
	COLOR *= color * texture(tex, SCREEN_UV * scale);
}
