shader_type canvas_item;
render_mode blend_add;

uniform sampler2D mask: source_color;

void fragment() {
	float change_x = dFdx(UV.x);
    float width = max(10, 1.0 / abs(change_x));
	COLOR.a *= smoothstep(0.45, 0.55, fract(UV.x * round(width / 10.0) +  2.0 * UV.y));
	COLOR.a *= texture(mask, UV).a;
}
