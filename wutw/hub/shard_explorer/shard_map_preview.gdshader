shader_type canvas_item;

group_uniforms dynamic;
uniform float fade: hint_range(0.0, 1.0) = 1.0;

group_uniforms static;

uniform sampler2D mask: repeat_enable;
uniform vec4 background_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D background_texture: repeat_enable;
uniform vec2 background_tiling = vec2(1.0, 1.0);

uniform vec4 pattern_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D pattern_texture: repeat_enable;
uniform vec2 pattern_tiling = vec2(1.0, 1.0);

uniform float darkening: hint_range(0.0, 1.0) = 0.4;

uniform float u_threshold1: hint_range(0.0, 1.0) = 0.75;
uniform float u_threshold2: hint_range(0.0, 1.0) = 0.50;
uniform float u_threshold3: hint_range(0.0, 1.0) = 0.25;
uniform float u_threshold4: hint_range(0.0, 1.0) = 0.05;

const float C2_SQRT2 = 0.707106781;
const mat2 ROT_45 = mat2(vec2(C2_SQRT2, -C2_SQRT2), vec2(C2_SQRT2, C2_SQRT2));

float get_intensity(vec3 color) {
	return 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
}

vec4 get_pattern_color(vec2 uv, float intensity) {
	vec4 sample1 = texture(pattern_texture, uv * pattern_tiling);
	vec4 sample2 = texture(pattern_texture, vec2(-uv.x, uv.y) * pattern_tiling);
	vec4 sample3 = texture(pattern_texture, ROT_45 * (uv + vec2(0.2358, 0.3123)) * pattern_tiling);
	vec4 sample4 = texture(pattern_texture, (vec2(uv.x, -uv.y) + vec2(0.4123, 0.7218)) * pattern_tiling);

	if (intensity > u_threshold1) {
		return vec4(1.0, 1.0, 1.0, 1.0);
	} else if (intensity > u_threshold2) {
		return mix(sample1, vec4(1), 0.5);
	} else if (intensity > u_threshold3) {
		return mix(sample1 * sample2, vec4(1), 0.3);
	} else if (intensity > u_threshold4) {
		return mix(sample1 * sample2 * sample3, vec4(1), 0.1);
	} else {
		return sample1 * sample2 * sample3 * sample4;
	}
}

void fragment() {
	vec4 orig_color = texture(TEXTURE, UV);
	float intensity = get_intensity(orig_color.rgb);
	vec4 background = mix(texture(background_texture, UV * background_tiling), background_color, darkening);
	vec4 foreground = get_pattern_color(UV, intensity);
	vec4 color = mix(pattern_color, background, get_intensity(foreground.rgb));
	COLOR = mix(orig_color, color, fade * COLOR.a);
	COLOR.a *= texture(mask, UV).a;
}
