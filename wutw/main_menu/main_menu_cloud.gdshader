shader_type canvas_item;

uniform sampler2D gradient: repeat_disable, filter_linear;
uniform sampler2D canvas: repeat_disable, filter_linear_mipmap_anisotropic;
uniform float canvas_scale = 1.0;
uniform vec3 base_color: source_color = vec3(1,1,1);

void fragment() {
	COLOR.rgb *= base_color * texture(canvas, SCREEN_UV * canvas_scale).rgb;
	float horizon_fade = texture(gradient, vec2(0, SCREEN_UV.y)).a;
	COLOR.a *= horizon_fade;
}
