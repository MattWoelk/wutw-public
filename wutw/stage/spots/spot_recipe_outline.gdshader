shader_type canvas_item;

uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed: hint_range(0.5, 20, 0.5) = 3.0;
uniform vec2 expand = vec2(2.0, 2.0);

void vertex() {
    // Add margin to show the outline outside the original area.
    VERTEX += (UV * 2.0 - 1.0) * expand;
}

void fragment() {
  COLOR.rgb = color.rgb;
  COLOR.a *= 1.0 + sin(TIME * speed) * 0.5;
  COLOR.a *= color.a;
}
