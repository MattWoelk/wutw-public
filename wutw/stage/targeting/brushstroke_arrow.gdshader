shader_type canvas_item;

uniform float arrowhead_pixels = 100.0;
uniform float arrowhead_u = 0.2;
uniform vec3 color: source_color = vec3(0.7, 0.0, 0.0);
uniform float glow_speed = 1.0;
uniform float band_period = 0.1;
uniform float band_exponent = 10.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.5, 1.0);

#include "res://visuals/shaders/utils.gdshaderinc"

void fragment() {
    // Estimate sprite width.
    float dudx = dFdx(UV.x);
    float dudy = dFdy(UV.x);
    float dU = sqrt(dudx * dudx + dudy * dudy);
    float sprite_width = 1.0 / dU;

    // Horizontal position in pixels.
    float pixel_x = UV.x * sprite_width;

    float new_u;
    if (pixel_x < arrowhead_pixels) {
        // Arrowhead: map 0-arrowhead_pixels to 0-0.2 U.
        new_u = (pixel_x / arrowhead_pixels) * arrowhead_u;
    } else {
        // Tail: map arrowhead_pixels-1 to 0.2-1 U.
        new_u = arrowhead_u + ((pixel_x - arrowhead_pixels) / (sprite_width - arrowhead_pixels)) * (1.0 - arrowhead_u);
    }

    vec2 new_uv = vec2(new_u, UV.y);
    vec4 original_color = texture(TEXTURE, new_uv);
	
    // Moving glow bands.
    float tail_u = new_u - arrowhead_u;
    float pos = (tail_u / band_period) - (TIME * glow_speed);
    float band = max(0.0, cos(TAU * pos));
    band = pow(band, band_exponent);
    
    // Fade out glow along the tail.
    float tail_fade = clamp((0.5 - new_u) / (arrowhead_u - 0.0), 0.0, 1.0);
    float glow_intensity = band * tail_fade;
	
    // Arrowhead is always glowing.
    float head_fade = smoothstep(arrowhead_u, 0, new_u);//clamp((0.5 - new_u) / (0.2 - 0.0), 0.0, 1.0);
    glow_intensity += head_fade * 0.8;
    
    vec4 final_glow_color = glow_intensity * glow_color;
	
	COLOR = vec4(color.rgb + final_glow_color.rgb, COLOR.a * smoothstep(0.1, 0.9, 1.0 - original_color.g));
	
	// Fade out tail tip.
	COLOR.a *= remap(UV.x, 0.5, 0.85, 1, 0);
}
