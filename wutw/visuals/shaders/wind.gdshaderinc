
#include "res://visuals/shaders/utils.gdshaderinc"

group_uniforms wind;
uniform sampler2D wind_noise: filter_linear_mipmap_anisotropic, repeat_enable;
uniform float wind_speed = 0.074;

float get_wind(vec2 global_center) {
	vec2 wind_uv = global_center / 1000.0;
	wind_uv.x += TIME * wind_speed;
	float wind_noise_sample = texture(wind_noise, wind_uv).r;
	return wind_noise_sample;
}
