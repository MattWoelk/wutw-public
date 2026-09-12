shader_type canvas_item;
render_mode blend_add;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

uniform float speed : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float offset : hint_range(0.0, 1.0, 0.01) = 0.13;
uniform sampler2D inv_mask : repeat_disable, filter_linear_mipmap_anisotropic;
uniform vec4 inv_mask_rect;

void fragment() {
	float dist = -sdf_circle(UV - vec2(0.5, 0.5), 0.5);
	vec4 color = texture(TEXTURE, vec2(dist + TIME * speed, 0.5));
	vec4 color2 = texture(TEXTURE, vec2(dist + offset + TIME * speed, 0.5));
	float modulate_alpha = COLOR.a;
	COLOR = mix(color, color2, 0.5);
	COLOR.a *= dist;
	COLOR.a *= modulate_alpha;

	vec2 mask_uv = vec2(remap(UV.x, 0, 1, inv_mask_rect.x, inv_mask_rect.z),
						remap(UV.y, 0, 1, inv_mask_rect.y, inv_mask_rect.w));
	COLOR.a *= 1.0 - texture(inv_mask, mask_uv).a;
}
