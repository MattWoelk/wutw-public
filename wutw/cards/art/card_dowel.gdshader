shader_type canvas_item;

uniform sampler2D color_tex: repeat_enable;
uniform sampler2D lines_tex: repeat_disable;
uniform sampler2D shade_tex: repeat_disable;
uniform vec4 color_uv_transform = vec4(1.0, 1.0, 0.0, 0.0);
uniform vec4 shade_uv_transform = vec4(1.0, 1.0, 0.0, 0.0);
uniform vec4 lines_uv_transform = vec4(1.0, 1.0, 0.0, 0.0);

uniform float reveal_lines_margin : hint_range(0.0, 1.0, 0.01) = 0.1;
instance uniform float reveal_lines_progress : hint_range(0.0, 1.0, 0.01) = 1.0;

uniform float reveal_margin : hint_range(0.0, 1.0, 0.01) = 0.1;
instance uniform float reveal_progress : hint_range(-0.3, 1.0, 0.01) = 1.0;
instance uniform float anim_offset : hint_range(0.0, 3.2, 0.01) = 3.2;

void fragment() {
	vec3 color = texture(color_tex, (UV + vec2(0, anim_offset)) * color_uv_transform.rg + color_uv_transform.ba).rgb;
	COLOR.rgb = color;

	vec4 shade_color = texture(shade_tex, UV * shade_uv_transform.rg + shade_uv_transform.ba);
	COLOR.rgb = shade_color.rgb * shade_color.a + COLOR.rgb * (1.0 - shade_color.a);

	vec2 lines_uv = UV * lines_uv_transform.rg + lines_uv_transform.ba;
	vec4 lines_color = texture(lines_tex, lines_uv);
	lines_color.a *= smoothstep(1.0 - reveal_lines_progress - reveal_lines_margin, 1.0 - reveal_lines_progress, 1.0 - lines_uv.x);
	COLOR.rgb = lines_color.rgb * lines_color.a + COLOR.rgb * (1.0 - lines_color.a);

	float mask = texture(TEXTURE, UV).a;
	mask *= smoothstep(1.0 - reveal_progress - reveal_margin, 1.0 - reveal_progress, 1.0 - UV.x);
	mask = max(mask, lines_color.a);
	COLOR.a *= mask;
}
