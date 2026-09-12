shader_type canvas_item;

group_uniforms dynamic;
instance uniform float state: hint_range(-1.0, 2.0, 0.01) = 0.0;
instance uniform vec2 background_offset = vec2(0, 0);  // normalized UV
uniform sampler2D decor_tex: repeat_disable, filter_linear_mipmap_anisotropic;

group_uniforms mask;
uniform sampler2D mask_tex: repeat_disable;

group_uniforms background;
uniform sampler2D background: repeat_enable;
uniform sampler2D gradient: repeat_enable;
uniform vec2 background_tex_size = vec2(635, 249);  // px
uniform float background_scale = 1.0;
uniform vec2 decor_size = vec2(1004, 784);
uniform float decor_scale = 1.7;
uniform float decor_alpha = 0.58;

group_uniforms outline;
uniform sampler2D outline_tex: repeat_disable;
uniform vec2 outline_tex_size = vec2(646, 259);  // px
uniform vec4 outline_margin = vec4(0);  // px
uniform float outline_scale = 1.0;

group_uniforms swish;
uniform sampler2D swish_right_tex: repeat_disable, filter_linear_mipmap;
uniform vec4 swish_right_transform = vec4(0.0, 0.0, 300.0, 100.0);  // pos.x, pos.y, width, height, all pixels.
uniform sampler2D swish_left_tex: repeat_disable, filter_linear_mipmap;
uniform vec4 swish_left_transform = vec4(0.0, 0.0, 300.0, 100.0);  // pos.x, pos.y, width, height, all pixels.

group_uniforms hover;
uniform float hover_distance = 2.0;

#include "res://visuals/shaders/utils.gdshaderinc"

vec2 nine_slice(vec2 uv, vec2 size) {
	// Convert input coordinates.
	vec2 local_pos = uv * size;
	vec2 frame_size_scaled = outline_tex_size / outline_scale;

	// Margins in pixels.
	float margin_left = outline_margin.x;
	float margin_top = outline_margin.y;
	float margin_right = outline_margin.z;
	float margin_bottom = outline_margin.w;

	// Margins in texture UV space.
	float tex_left = margin_left / frame_size_scaled.x;
	float tex_top = margin_top / frame_size_scaled.y;
	float tex_right = 1.0 - margin_right / frame_size_scaled.x;
	float tex_bottom = 1.0 - margin_bottom / frame_size_scaled.y;

	// Margins in output coordinates.
	float offset_left = margin_left;
	float offset_top = margin_top;
	float offset_right = size.x - margin_right;
	float offset_bottom = size.y - margin_bottom;

	vec2 tex_uv = vec2(0.0);

	// X axis
	if (local_pos.x < offset_left) { // Left border (corner/edge).
	    tex_uv.x = local_pos.x / offset_left * tex_left;
		//COLOR.r = 1.0;
	} else if (local_pos.x >= offset_right) { // Right border (corner/edge).
		//COLOR.g = 1.0;
	    float border_width = size.x - offset_right;
	    tex_uv.x = tex_right + (local_pos.x - offset_right) / border_width * (1.0 - tex_right);
	} else { // Middle (stretch horizontally).
		tex_uv.x = remap(local_pos.x, offset_left, offset_right, tex_left, tex_right);
	}

	// Y axis
	if (local_pos.y < offset_top) { // Top border (corner/edge).
		//COLOR.b = 1.0;
	    tex_uv.y = local_pos.y / offset_top * tex_top;
	} else if (local_pos.y >= offset_bottom) { // Bottom border (corner/edge).
		//COLOR.g = 1.0;
	    float border_height = size.y - offset_bottom;
	    tex_uv.y = tex_bottom + (local_pos.y - offset_bottom) / border_height * (1.0 - tex_bottom);
	} else { // Middle (stretch vertically).
		tex_uv.y = remap(local_pos.y, offset_top, offset_bottom, tex_top, tex_bottom);
	}

	return tex_uv;
}

vec2 align_right_fit_height(vec2 uv, vec2 surface_size, vec2 tex_size, float scale) {
	float aspect = surface_size.x / surface_size.y;
	float tex_aspect = tex_size.x / tex_size.y;
	float width_in_uv = tex_aspect / aspect;
	return vec2((uv.x - 1.0) / (width_in_uv * scale) + 1.0,
				(uv.y - 1.0) / scale + 1.0);
}

float get_swish_alpha(vec2 uv, float min_angle, float max_angle, float threshold) {
	vec2 center_uv = uv - vec2(0.5);
	float a = atan(center_uv.y, center_uv.x);
	float angle = (atan(center_uv.x, center_uv.y) + PI) / TAU;
	float t = remap(angle, min_angle, max_angle, 0.0, 1.0);
	return 1.0 - smoothstep(threshold - 0.1, threshold, t);
}

void vertex() {
	VERTEX.y -= hover_distance * sin(PI * clamp(state, 0, 2) / 2.0);
}

void fragment() {
	float change_x = dFdx(UV.x);
    float change_y = dFdy(UV.y);
    vec2 size = vec2(max(50, 1.0 / abs(change_x)), max(30, 1.0 / abs(change_y)));

	if (TEXTURE_PIXEL_SIZE.x > 0.5) {  // HACK: Filter out text.
		vec2 local_pos = UV * size;
		vec4 color;

		// Background texture.
		vec2 background_size_scaled = background_tex_size / background_scale;
		color.rgb = texture(background, (local_pos / background_size_scaled) + background_offset).rgb;

		// Background shade.
		vec4 shade_sample = texture(gradient, UV);
		color.rgb = mix(color.rgb, color.rgb * shade_sample.rgb, shade_sample.a);

		// Hover highlight.
		color.rgb *= (1.0 + clamp(state, 0, 1) * 0.1);

		// Decor.
		vec2 decor_uv = align_right_fit_height(UV, size, decor_size, decor_scale);
		vec4 decor_color = texture(decor_tex, decor_uv);
		color.rgb = mix(color.rgb, decor_color.rgb, decor_color.a * decor_alpha);

		// Right (hover) swish.
		vec2 swish_r_top_left = size - vec2(swish_right_transform.z, swish_right_transform.w) + swish_right_transform.xy;
		vec2 swish_r_size = vec2(swish_right_transform.z, swish_right_transform.w);
		if (all(greaterThanEqual(local_pos, swish_r_top_left)) &&
			all(lessThan(local_pos, swish_r_top_left + swish_r_size))) {
			vec2 swish_r_uv = (local_pos - swish_r_top_left) / swish_r_size;
			vec4 swish_r_color = texture(swish_right_tex, swish_r_uv);
			swish_r_color.a *= get_swish_alpha(UV, .6, .9, state);
			color.rgb = mix(color.rgb, swish_r_color.rgb, swish_r_color.a);
		}

		// Left (pressed) swish.
		vec2 swish_l_top_left = size - vec2(swish_left_transform.z, swish_left_transform.w) + swish_left_transform.xy;
		vec2 swish_l_size = vec2(swish_left_transform.z, swish_left_transform.w);
		if (all(lessThan(local_pos, swish_l_size))) {
			vec2 swish_l_uv = local_pos / swish_l_size;
			vec4 swish_l_color = texture(swish_left_tex, swish_l_uv);
			swish_l_color.a *= get_swish_alpha(UV, .1, .45, state);
			color.rgb = mix(color.rgb, swish_l_color.rgb, swish_l_color.a);
		}

		// Frame.
		vec2 sliced_uv = nine_slice(UV, size);
		vec4 outline_sample = texture(outline_tex, sliced_uv);
		color.rgb = mix(color.rgb, outline_sample.rgb, outline_sample.a);

		// Mask.
		vec4 mask_sample = texture(mask_tex, sliced_uv);
		color.a = mask_sample.a;

		// Handle disabled state.
		color *= 1.0 + clamp(state, -1, 0) * 0.3;

		// Output.
		COLOR *= color;
	}
}