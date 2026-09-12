shader_type canvas_item;

uniform float clip_offset: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float clip_width: hint_range(0.0, 1.0, 0.01) = 0.01;
uniform vec4 ground_color: source_color = vec4(0.5, 0.5, 0.0, 1.0);

uniform float border_offset: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float border_width: hint_range(0.0, 1.0, 0.01) = 0.05;
uniform vec4 border_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float noise_scale : hint_range(1, 10000) = 200;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	vec3 dist3 = texture(TEXTURE, UV).rgb;
	float dist = max(min(dist3.r, dist3.g), min(max(dist3.r, dist3.g), dist3.b));
	COLOR.a = smoothstep(clip_offset, clip_offset + clip_width, dist) * ground_color.a;
	COLOR.rgb = ground_color.rgb;

	float border_alpha1 = smoothstep(border_offset - border_width, border_offset, dist);
	float border_alpha2 = 1.0 - smoothstep(border_offset, border_offset + border_width, dist);
	float border_alpha =  border_alpha1 *  border_alpha2;

	vec2 square_uv = UV;
	square_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	float noise = value_noise_2_1_smooth(square_uv * noise_scale, noise_smoothness);
	border_alpha *= (1.0 - noise * noise_strength);

	COLOR.rgb = mix(COLOR.rgb, border_color.rgb, border_alpha * border_color.a);
	COLOR.a += border_alpha;
}
