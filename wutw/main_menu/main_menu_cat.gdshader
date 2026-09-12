shader_type canvas_item;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"

const float BLACK_THRESHOLD = 0.27;

void fragment() {
	if (lightest(COLOR.rgb) <= BLACK_THRESHOLD) {
		float noise = value_noise_2_1_smooth(UV * 100.0, 1.0);
		noise = remap(noise, 0, 1, 0.4, 1.5);
		COLOR.rgb = vec3(BLACK_THRESHOLD * noise);
	}
}
