shader_type canvas_item;

// Configurable axis directions (in pixels, relative to the grid origin)
uniform vec2 axis1 = vec2(32.0, 16.0);
uniform vec2 axis2 = vec2(-32.0, 16.0);

uniform float line_width : hint_range(0.5, 10.0) = 1.5;

void fragment() {
    // The position in the local canvas item (pixels)
    vec2 pos = UV.xy * vec2(1920, 1080);
    
    // Project the current pixel onto the two axes
    float proj1 = dot(pos, axis1) / dot(axis1, axis1);
    float proj2 = dot(pos, axis2) / dot(axis2, axis2);

    // Get the local "cell" coordinates (between 0 and 1 for each axis)
    float cell1 = fract(proj1);
    float cell2 = fract(proj2);

    // Find distance to the nearest line for each axis (in axis units)
    float dist1 = min(cell1, 1.0 - cell1) * length(axis1);
    float dist2 = min(cell2, 1.0 - cell2) * length(axis2);

    // Draw line if either axis is close enough
    float line_dist = min(dist1, dist2);

    float alpha = smoothstep(line_width + 0.5, line_width - 0.5, line_dist);

    // Composite the colors
    COLOR.a = alpha;
}
