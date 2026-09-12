shader_type canvas_item;
#include "res://visuals/shaders/wind.gdshaderinc"

uniform float wind_amplitude = 20.0;

uniform sampler2D gradient: repeat_disable, filter_linear_mipmap_anisotropic;
uniform sampler2D noise: repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec2 direction = vec2(0.0, 1.0);
uniform float scale: hint_range(0.01, 1.0, 0.01) = 1.0;
uniform float speed: hint_range(0.0, 0.5, 0.01) = 0.5;
uniform float strength: hint_range(0.0, 0.5, 0.001) = 1.0;

#include "res://visuals/shaders/utils.gdshaderinc"

void vertex() {
	vec2 object_location = vec2(MODEL_MATRIX[3][0], MODEL_MATRIX[3][1]);
	float height_factor = remap(UV.y, 0.0, 0.6, 1.0, 0);
	float remapped_wind = remap(get_wind(object_location), 0.0, 1.0, -0.5, 1.0);
	VERTEX.x -= remapped_wind * height_factor * wind_amplitude * sign(MODEL_MATRIX[0][0]);
}

void fragment() {
	float noise_sample = texture(noise, UV * scale + vec2(TIME * speed, 0)).r;
	float impact = 1.0 - texture(gradient, UV).r;
	vec2 uv = UV + (direction * noise_sample * impact * strength);
	COLOR = texture(TEXTURE, uv);
}
