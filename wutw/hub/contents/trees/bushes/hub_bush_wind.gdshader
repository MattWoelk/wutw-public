shader_type canvas_item;

#include "res://visuals/shaders/wind.gdshaderinc"

uniform float wind_amplitude = 20.0;
uniform sampler2D wind_tex;

void vertex() {
	vec2 object_location = vec2(MODEL_MATRIX[3][0], MODEL_MATRIX[3][1]);
	float height_factor = texture(wind_tex, UV).r;
	float remapped_wind = remap(get_wind(object_location), 0.0, 1.0, -0.5, 1.0);
	VERTEX.x -= remapped_wind * height_factor * wind_amplitude * sign(MODEL_MATRIX[0][0]);
}
