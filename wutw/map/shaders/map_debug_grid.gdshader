shader_type canvas_item;

uniform vec3[20] biome_colors : source_color;
uniform vec2 texture_size = vec2(455, 256);
uniform float border_size : hint_range(0, 1) = 0.15;
uniform float alpha : hint_range(0, 1) = 0.5;

void fragment() {
	vec2 coord = texture_size * UV;
	int biome = int(round(texture(TEXTURE, UV).r * 255.0));
	COLOR.rgb = biome_colors[biome];
	COLOR.a = alpha;
	if (fract(coord.x) < border_size || fract(coord.y) < border_size)
	{
		COLOR.rgb = vec3(0,0,0);
	}
}
