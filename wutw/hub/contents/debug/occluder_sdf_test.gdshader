shader_type canvas_item;
render_mode unshaded;
void fragment() {
    float distance_cut_off = 50.0; //px
    vec2 at = screen_uv_to_sdf(SCREEN_UV);
    COLOR.rgb = vec3((texture_sdf(at)+ distance_cut_off/2.0)/distance_cut_off);
}