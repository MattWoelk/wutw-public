shader_type canvas_item;

group_uniforms dynamic;
uniform vec2 size = vec2(100.0, 100.0);
uniform float scroll_offset: hint_range(0.0, 1.0, 0.01) = 0.0;

group_uniforms config;

uniform sampler2D wood_tex: repeat_enable;
uniform vec2 wood_tex_scale = vec2(1.0, 1.0);

uniform sampler2D gradient_tex: repeat_enable;
uniform float gradient_factor: hint_range(0.0, 2.0, 0.01) = 1.0;

uniform sampler2D noise_tex: repeat_enable;
uniform vec2 noise_scale = vec2(100.0, 100.0);

void fragment() {
	COLOR.rgb = texture(wood_tex, UV * wood_tex_scale * size / 100.0 + vec2(0.0, scroll_offset * 0.9)).rgb;

	float noise = texture(noise_tex, UV * size / noise_scale + vec2(0.0, scroll_offset * 0.9)).r;
	vec4 gradient = texture(gradient_tex, UV);
	COLOR.rgb *= mix(vec3(1), gradient.rgb * noise, gradient.a * gradient_factor);
}
