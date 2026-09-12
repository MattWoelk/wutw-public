shader_type canvas_item;

group_uniforms base_color;
uniform float base_gradient_range : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform sampler2D base_gradient : filter_linear_mipmap_anisotropic;

group_uniforms interior_noise;
uniform vec4 base_noise_color: source_color = vec4(0, 0, 0, 1);
uniform float base_noise_scale : hint_range(1, 3000) = 200;
uniform float base_noise_smoothness : hint_range(0.01, 1.0) = 1.0;

group_uniforms edge;
uniform sampler2D edge_gradient : filter_linear_mipmap_anisotropic;
uniform float edge_noise_scale : hint_range(1, 3000) = 325;
uniform float edge_noise_smoothness : hint_range(0.01, 1.0) = 1.0;

//group_uniforms strokes;
//uniform vec4 stroke_color: source_color = vec4(1, 0, 0, 1);

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

void fragment() {
	vec2 square_uv = UV;
	square_uv.x *= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	
	// Start with a base color and alpha from gradient + distance.
	float area_dist = texture(TEXTURE, UV).r;
	float area_dist_unit = remap(area_dist, 0.5 - base_gradient_range, 0.5 + base_gradient_range, 0.0, 1.0);
	COLOR.rgba = texture(base_gradient, vec2(area_dist_unit, 0.5));
	
	// Determine area edge.
	vec4 edge_color = texture(edge_gradient, vec2(area_dist_unit, 0.5));
	
	// Add noise, differently for the edge and the interior.
	// Edge noise.
	float edge_noise = value_noise_2_1_smooth(square_uv * edge_noise_scale, edge_noise_smoothness);
	float edge_noise_alpha = edge_color.a * edge_noise;
	COLOR.rgb = mix(COLOR.rgb, edge_color.rgb, edge_color.a * edge_noise);
	
	// Interior noise.
	float noise_amount = value_noise_2_1_smooth(square_uv * base_noise_scale, base_noise_smoothness);
	COLOR.rgb = mix(COLOR.rgb, base_noise_color.rgb, noise_amount * base_noise_color.a);
	
	
	
	//COLOR.rgba = edge_color;
	//COLOR.rgba = vec4(edge_noise_alpha, 0., 0., 1.);
}
