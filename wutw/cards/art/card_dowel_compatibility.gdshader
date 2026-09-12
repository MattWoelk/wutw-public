shader_type canvas_item;

uniform sampler2D color_tex: repeat_enable;
uniform sampler2D lines_tex: repeat_disable;
uniform sampler2D shade_tex: repeat_disable;
uniform vec4 color_uv_transform = vec4(1.0, 1.0, 0.0, 0.0);
uniform vec4 shade_uv_transform = vec4(1.0, 1.0, 0.0, 0.0);
uniform vec4 lines_uv_transform = vec4(1.0, 1.0, 0.0, 0.0);

void fragment() {
	vec3 color = texture(color_tex, (UV) * color_uv_transform.rg + color_uv_transform.ba).rgb;
	COLOR.rgb = color;

	vec4 shade_color = texture(shade_tex, UV * shade_uv_transform.rg + shade_uv_transform.ba);
	COLOR.rgb = shade_color.rgb * shade_color.a + COLOR.rgb * (1.0 - shade_color.a);

	vec2 lines_uv = UV * lines_uv_transform.rg + lines_uv_transform.ba;
	vec4 lines_color = texture(lines_tex, lines_uv);
	COLOR.rgb = lines_color.rgb * lines_color.a + COLOR.rgb * (1.0 - lines_color.a);
}
