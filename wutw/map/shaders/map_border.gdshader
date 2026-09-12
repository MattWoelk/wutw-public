shader_type canvas_item;

uniform float outline_width : hint_range(0.00, 0.1, 0.001) = 0.05;  // in normalized SDF units (0.0–1.0)
uniform float falloff : hint_range(0.00, 0.1, 0.001) = 0.02;        // fade softness
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float noise_scale : hint_range(1, 10000) = 200;
uniform float noise_strength : hint_range(0.0, 2.0) = 1.1;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;

#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
    float sdf = texture(TEXTURE, UV).r;
    float dist = sdf - 0.5;

    float half_width = outline_width * 0.5;

    // Compute alpha using smoothstep for soft edges
    float alpha = smoothstep(0.5 - outline_width + falloff, 0.5 - outline_width, sdf);
    float alpha2 = 1.0 - smoothstep(0.5 - outline_width, 0.5 - outline_width - falloff, sdf);
    float alpha_composed = alpha2 * alpha;

	vec2 square_uv = UV;
	square_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	float noise = value_noise_2_1_smooth(square_uv * noise_scale, noise_smoothness);
	COLOR.rgb = outline_color.rgb;
	COLOR.a *= clamp(outline_color.a * alpha_composed * (1.0 - noise * noise_strength), 0.0, 1.0);
}
