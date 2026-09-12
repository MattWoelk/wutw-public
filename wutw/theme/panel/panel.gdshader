shader_type canvas_item;

group_uniforms background;
uniform sampler2D background: repeat_enable;
uniform sampler2D background_shade: repeat_enable;
uniform vec2 background_tex_size = vec2(3118, 2291);  // px
uniform float background_scale = 1.0;

group_uniforms frame;
uniform sampler2D frame_tex: repeat_disable;
uniform vec2 frame_tex_size = vec2(1024, 695);  // px
uniform vec4 frame_margin = vec4(0);  // px
uniform float frame_scale = 1.0;
uniform vec3 frame_color: source_color = vec3(0);

group_uniforms decor;
uniform sampler2D decor_tex: repeat_disable, filter_linear_mipmap;
uniform vec4 decor_transform = vec4(0.0, 0.0, 300.0, 100.0);  // pos.x, pos.y, width, height, all pixels.
uniform vec4 decor_modulate: source_color = vec4(1, 1, 1, 0);

#include "res://visuals/shaders/utils.gdshaderinc"

vec2 nine_slice(vec2 uv, vec2 rendered_size) {
	// Convert input coordinates.
	vec2 local_pos = uv * rendered_size;
	vec2 frame_size_scaled = frame_tex_size / frame_scale;

	// Margins in pixels.
	float margin_left = frame_margin.x;
	float margin_top = frame_margin.y;
	float margin_right = frame_margin.z;
	float margin_bottom = frame_margin.w;

	// Margins in texture UV space.
	float tex_left = margin_left / frame_size_scaled.x;
	float tex_top = margin_top / frame_size_scaled.y;
	float tex_right = 1.0 - margin_right / frame_size_scaled.x;
	float tex_bottom = 1.0 - margin_bottom / frame_size_scaled.y;

	// Margins in output coordinates.
	float offset_left = margin_left;
	float offset_top = margin_top;
	float offset_right = rendered_size.x - margin_right;
	float offset_bottom = rendered_size.y - margin_bottom;

	vec2 tex_uv = vec2(0.0);

	// X axis
	if (local_pos.x < offset_left) { // Left border (corner/edge).
	    tex_uv.x = local_pos.x / offset_left * tex_left;
		//COLOR.r = 1.0;
	} else if (local_pos.x >= offset_right) { // Right border (corner/edge).
		//COLOR.g = 1.0;
	    float border_width = rendered_size.x - offset_right;
	    tex_uv.x = tex_right + (local_pos.x - offset_right) / border_width * (1.0 - tex_right);
	} else { // Middle (repeat/tile horizontally).
	    float mid_width = offset_right - offset_left;
	    float tex_mid_width = tex_right - tex_left;
	    float pos_in_mid = mod(local_pos.x - offset_left, tex_mid_width * frame_size_scaled.x);
	    tex_uv.x = tex_left + pos_in_mid / frame_size_scaled.x;
	}

	// Y axis
	if (local_pos.y < offset_top) { // Top border (corner/edge).
		//COLOR.b = 1.0;
	    tex_uv.y = local_pos.y / offset_top * tex_top;
	} else if (local_pos.y >= offset_bottom) { // Bottom border (corner/edge).
		//COLOR.g = 1.0;
	    float border_height = rendered_size.y - offset_bottom;
	    tex_uv.y = tex_bottom + (local_pos.y - offset_bottom) / border_height * (1.0 - tex_bottom);
	} else { // Middle (repeat/tile vertically).
	    float mid_height = offset_bottom - offset_top;
	    float tex_mid_height = tex_bottom - tex_top;
	    float pos_in_mid = mod(local_pos.y - offset_top, tex_mid_height * frame_size_scaled.y);
	    tex_uv.y = tex_top + pos_in_mid / frame_size_scaled.y;
	}

	return tex_uv;
}

void fragment() {
	float change_x = dFdx(UV.x);
    float change_y = dFdy(UV.y);
    vec2 size = vec2(max(10, 1.0 / abs(change_x)), max(10, 1.0 / abs(change_y)));

	vec2 local_pos = UV * size;
	vec4 color;

	// Background texture.
	vec2 background_size_scaled = background_tex_size / background_scale;
	color.rgb = texture(background, (local_pos / background_size_scaled)).rgb;

	// Decor.
	float decor_alpha = 0.0;
	if (decor_modulate.a > 0.0) {
		// Compute the top-left corner of the decor texture in canvas coords.
		// Offset is negative because decor_transform.xy is relative to bottom right.
		vec2 decor_top_left = size - vec2(decor_transform.z, decor_transform.w) + decor_transform.xy;
		vec2 decor_size = vec2(decor_transform.z, decor_transform.w);
		// Check if the pixel is inside the decor rect.
		if (all(greaterThanEqual(local_pos, decor_top_left)) && all(lessThan(local_pos, decor_top_left + decor_size))) {
			// Compute UV for the decor texture
			vec2 decor_uv = (local_pos - decor_top_left) / decor_size;
			vec4 decor_color = texture(decor_tex, decor_uv);
			decor_alpha = decor_color.a;
			color.rgb = mix(color.rgb, decor_color.rgb * decor_modulate.rgb, decor_color.a * decor_modulate.a);
		}
	}

	// Background shade.
	vec4 shade_sample = texture(background_shade, UV);
	color.rgb = mix(color.rgb, color.rgb * shade_sample.rgb, shade_sample.a * (1.0 - decor_alpha));

	// Frame.
	vec4 frame_sample = texture(frame_tex, nine_slice(UV, size));

	// Output.
	color.rgb *= mix(color.rgb, frame_color, frame_sample.g);
	// This is more correct, but we already depend on the above.
	//color.rgb *= mix(vec3(1), frame_color, frame_sample.g);
	color.a = frame_sample.r;

	COLOR *= color;
}
