shader_type canvas_item;

group_uniforms dynamic;
uniform sampler2D image: filter_linear_mipmap, repeat_disable;
uniform vec2 image_size = vec2(1, 1);

group_uniforms config;
uniform sampler2D mask: filter_linear_mipmap, repeat_disable;
uniform vec2 slot_size = vec2(100, 100);
uniform vec2 area_uv_offset = vec2(0.2, 0.2);
uniform vec2 area_uv_size = vec2(0.6, 0.6);
uniform float skew_x = 0.0;
uniform float skew_y = 0.2;

group_uniforms wind;
uniform vec2 wind_direction = vec2(-1.8, -1);
uniform float wind_strength : hint_range(0.0, 0.1, 0.001) = 0.016;

#include "res://visuals/shaders/wind.gdshaderinc"

varying vec2 object_location;

void vertex() {
	object_location = vec2(MODEL_MATRIX[3][0], MODEL_MATRIX[3][1]);
}

void fragment() {
	vec4 modulate = COLOR / texture(TEXTURE, UV);
	
	// Wind deforms the whole exhibit (e.g. curtain)
	float wind_influence = texture(mask, UV).g;
	vec2 uv = UV;
	float remapped_wind = remap(get_wind(object_location), 0.0, 1.0, -1.0, 1.0);
	uv += remapped_wind * wind_influence * wind_strength * wind_direction;
	
	// Frame image
	vec2 image_uv = (uv - area_uv_offset) / area_uv_size;
	image_uv.x += (image_uv.y - 0.5) * skew_x;
	image_uv.y += (image_uv.x - 0.5) * skew_y;

	// Scale image to cover
	float slot_aspect = slot_size.x / slot_size.y;
	float image_aspect = image_size.x / image_size.y;
	vec2 scale = vec2(1.0);
	if (image_aspect > slot_aspect) {
		scale.x = image_aspect / slot_aspect;
	} else {
		scale.y = slot_aspect / image_aspect;
	}
	vec2 scaled_image_uv = (image_uv - 0.5) / scale + 0.5;
	
	// Assemble
	vec4 base = texture(TEXTURE, uv);
	float image_opacity = texture(mask, uv).r;
	vec4 image_value = texture(image, scaled_image_uv);
	COLOR.rgb = mix(base.rgb, image_value.rgb, image_opacity * image_value.a) * modulate.rgb;
	COLOR.a = base.a;
}
