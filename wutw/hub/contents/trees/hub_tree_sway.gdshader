shader_type canvas_item;

#include "res://visuals/shaders/wind.gdshaderinc"

uniform float wind_amplitude = 20.0;
uniform bool flip_y_impact = false;
uniform bool debug_on = false;
uniform float debug_factor: hint_range(-0.5, 1, 0.01) = 0;

void vertex() {
	vec2 object_location = vec2(MODEL_MATRIX[3][0], MODEL_MATRIX[3][1]);
	float height_factor = remap(UV.y, 0.0, 0.6, 1.0, 0);
	if (flip_y_impact) height_factor = 1.0 - height_factor;
	float remapped_wind = remap(get_wind(object_location), 0.0, 1.0, -0.5, 1.0);
	if (debug_on) {
		VERTEX.x -= debug_factor * height_factor * wind_amplitude * sign(MODEL_MATRIX[0][0]);
	} else {
		VERTEX.x -= remapped_wind * height_factor * wind_amplitude * sign(MODEL_MATRIX[0][0]);
	}
}
