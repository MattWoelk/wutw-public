shader_type canvas_item;

uniform int frame = 0;
uniform int frames_x = 3;
uniform int frames_y = 4;
uniform vec2 fadein_range = vec2(0.0, -0.1);
uniform vec2 fadeout_range = vec2(0.0, 1.0);
uniform float t: hint_range(0.0, 2.0, 0.01) = 1;

void fragment() {
	int frame_x = frame % frames_x;
	int frame_y = frame / frames_y;
	vec2 frame_offset = vec2(float(frame_x) / float(frames_x),
							float(frame_y) / float(frames_y));
	vec2 frame_uv = UV / vec2(float(frames_x), float(frames_y));
	vec4 color = texture(TEXTURE, frame_offset + frame_uv);
	
	float progress = distance(UV, vec2(0));
	if (t < 1.0) {
		color.a *= smoothstep(t + fadein_range.x, t + fadein_range.y, progress);
	} else if (t > 1.0) {
		color.a *= smoothstep((2.0 - t) + fadeout_range.x, (2.0 - t) + fadeout_range.y, 1.0 - progress);
		color.a *= smoothstep(2.0, 1.9, t);  // Hide tail for oversized ones.
	}
	COLOR = color;
}
