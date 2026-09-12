shader_type canvas_item;

group_uniforms dynamic;
uniform float progress: hint_range(0.0, 1.0) = 0.5;

group_uniforms geometry;
uniform vec2 center = vec2(0.5, 0.5);
uniform float max_dist: hint_range(0.0, 10.0) = 0.5;
uniform float fadein_margin: hint_range(0.0001, .2) = 0.03;
uniform float fadeout_margin: hint_range(0.0001, .2) = 0.08;
uniform int slices: hint_range(1, 100) = 10;
uniform float stripe_variation_frequency: hint_range(0.01, 1.5) = 0.7;
uniform float stripe_variation_factor: hint_range(0.01, 5.0) = 1.2;
uniform float aspect_ratio = 1.77777;
uniform float speed: hint_range(0.0001, 0.02) = 0.01;

group_uniforms colors;
uniform vec3 bg_color: source_color = vec3(0.0);
uniform sampler2D ray_gradient;
uniform float ray_gradient_scale: hint_range(0.01, 5.0) = 1.0;
uniform sampler2D overlay_tex;

group_uniforms noise;
uniform float noise_scale : hint_range(1, 10000) = 1376.0;
uniform float noise_strength : hint_range(0.0, 2.0) = 0.167;
uniform float noise_smoothness : hint_range(0.01, 1.0) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

float aa_stripe(float stripe_number) {
	// TODO: Fix seam artifact by fwidth()ing a unit vector at the angle.
	float w = fwidth(stripe_number) * PI;
	float signal = -sin(stripe_number * PI);
	return smoothstep(-w, w, signal);
}

void fragment() {
	vec2 square_uv = UV;
	square_uv.y /= aspect_ratio;
	vec2 square_center = center;
	square_center.y /= aspect_ratio;

	vec2 dist = square_uv - square_center;
	float angle = atan(dist.y, dist.x);
	float angle_normal = remap(angle, -PI, PI, 0, 1);
	angle_normal = fract(angle_normal - speed * TIME);
	float stripe_number = angle_normal * float(slices);
	float warped_stripe_number = stripe_number + sin(stripe_number * stripe_variation_frequency) * stripe_variation_factor;
	float ray_alpha = aa_stripe(warped_stripe_number);
	float ray_gradient_t = remap(length(dist), 0, ray_gradient_scale, 0, 1);
	vec3 ray_color = texture(ray_gradient, vec2(ray_gradient_t, 0.5)).rgb;
	COLOR.rgb = mix(ray_color, bg_color, ray_alpha);

	vec3 overlay_color = texture(overlay_tex, SCREEN_UV).rgb;
	COLOR.rgb *= overlay_color;

	float noise = value_noise_2_1_smooth(square_uv * noise_scale, noise_smoothness);
	COLOR.rgb -= noise * noise_strength - 0.1;

	float dist_normal = remap(length(dist), 0, max_dist, 0, 1);
	if (progress <= 0.5) {
		float fadein_progress = progress * 2.0;
		COLOR.a = smoothstep(fadein_progress, fadein_progress - fadein_margin, dist_normal);
	} else {
		float fadeout_progress = progress * 2.0 - 1.0;
		COLOR.a = smoothstep(fadeout_progress, fadeout_progress + fadeout_margin, dist_normal);
	}
}
