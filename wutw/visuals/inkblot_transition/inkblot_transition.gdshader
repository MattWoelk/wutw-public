shader_type canvas_item;

uniform sampler2D cleared_texture;
uniform sampler2D noise_tex: repeat_enable;
uniform vec3 modulate_color: source_color = vec3(1);
uniform float progress : hint_range(0.0, 2.0) = 0.0;
uniform int cells = 10;

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"

// Based on https://www.shadertoy.com/view/wsfcWB

float noise(in vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
	vec2 rg = texture(noise_tex, (uv + 0.5) / 25.0, -100.0).yx;
	return mix(rg.x, rg.y, f.z);
}

float sqrLen(vec2 vec) {
	return vec.x * vec.x + vec.y * vec.y;  
}

vec2 random2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))))* 43758.5453);
}

float signedDist2D(vec2 pos) {
	float dist = 1.0;
	for (int i = 0; i < int(cells); ++i) {
		dist = union(dist, sdf_circle(random2(vec2(float(i))), 1.0 / (float(cells) * 2.0)));
	}
	return dist;
}

float FX1(float dist, float noise, float expansion, float time) {
	float str = 0.9 + dist * pow(expansion, 2.0) * 0.8 * time;
	return pow(str, 20.0) * pow(noise, 6.0);
}

float FX2(float val, float noise, float expansion, float time) {    
    val *= expansion;
    return pow((1.0 + val * time) * expansion, 20.0) * pow(noise, 6.0);
}

float FX3(float val, float noise, float expansion, float time) {    
	val = clamp(val, 0.0, 1.0);
	float ins = FX2(val * pow(expansion - 0.5, 1.0), noise, expansion, time) * expansion;
	return ins / 20.0 + remap(0., 1.0, 0.0, 1.0, FX2(val, noise, expansion, time)) * expansion;;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV) * vec4(modulate_color, 1);
	
	vec4 from, to;
	float t;
	if (progress <= 1.0) {
		// Fade out.
		from = texture(cleared_texture, UV);
		to = base;
		t = progress;
	} else {
		from = base;
		to = vec4(from.rgb, 0.0);
		t = progress -1.0;
	}
	
    vec2 normalized_uv = vec2(UV.x - 0.5, 0.5 - UV.y);
	normalized_uv.y /= TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;

    float time = t * 25.0;
	
	vec3 scaledPos = 8.0 * vec3(normalized_uv, time * 0.0001);
	float noiseVal = 0.0;
	float ampl = 1.0;
	float maxValue = 0.0;
	for (float i = 0.0; i < 8.0; ++i) {
		noiseVal += noise(scaledPos) * ampl;
		scaledPos *= 2.0;
		maxValue += ampl;
		ampl *= 0.5;
	}
	noiseVal /= maxValue;

	float expansion = 0.8 - sqrLen(normalized_uv);
	expansion += time * time * 0.0006;    
	expansion = min(expansion, 1.0);

	float alpha;
	if (progress <= 1.0) {
		alpha = FX1(-signedDist2D(normalized_uv), noiseVal, expansion, time);
	} else {
		alpha = FX3(-signedDist2D(normalized_uv), noiseVal, expansion, time);
	}

	COLOR = mix(from, to, clamp(alpha, 0.0, 1.0));
}
