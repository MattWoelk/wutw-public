shader_type canvas_item;
render_mode skip_vertex_transform;

const int CUSTOM_DATA_BUFFER_WIDTH = 512;  // Must match BUFFER_WIDTH in map_sprite_renderer.cpp

// Constants for the MapSpriteType::InstanceType enum (see map_sprite_type.h):
const int TYPE_FOOTPRINT = 0;
const int TYPE_TREE = 1;
const int TYPE_TREE_DAUB_FIR = 2;
const int TYPE_MOUNTAIN = 3;
const int TYPE_GRASS = 4;
const int TYPE_GRASS_DAUB_DESERT = 5;
const int TYPE_GRASS_DAUB_FLOWER_1 = 6;
const int TYPE_GRASS_DAUB_FLOWER_2 = 7;
const int TYPE_GRASS_DAUB_FLOWER_3 = 8;
const int TYPE_HILL_PLAINS = 9;
const int TYPE_GENERIC = 10;
const int TYPE_RIVER = 11;
const int TYPE_SEA_WAVES = 12;
const int TYPE_DUNE = 13;
const int TYPE_GRASS_DAUB_STEPPE = 14;
const int TYPE_LAKE = 15;
const int TYPE_GRASS_DAUB_BUSH = 16;
const int TYPE_DAUB_GENERIC = 17;
const int TYPE_SWAMP_POND = 18;
const int TYPE_TREE_DAUB_WILLOW = 19;
const int TYPE_GRASS_DAUB_DRY = 20;
// DEPRECATED: const int TYPE_HILL_STEPPE = 21;
// DEPRECATED: const int TYPE_HILL_BRUSHLAND = 22;
const int TYPE_BUILDING = 23;
const int TYPE_WATERFALL = 24;
const int TYPE_TREE_DAUB_DECIDUOUS = 25;
const int TYPE_TREE_DAUB_SAKURA = 26;
const int TYPE_GLASS = 27;

// Constants for the MapSpriteType_Generic::AtlasType enum (see map_sprite_type_generic.h):
const int ATLAS_TYPE_VEGETATION = 0;
const int ATLAS_TYPE_BUILDINGS = 1;
const int ATLAS_TYPE_MOUNTAIN = 2;
const int ATLAS_TYPE_WATER_FEATURES = 3;

// Constants for the MapSpriteType_River::DirectionType enum (see map_sprite_type_river.h):
const int RIVER_DIRECTION_HORIZONTAL = 0;
const int RIVER_DIRECTION_VERTICAL = 1;
const int RIVER_DIRECTION_CORNER_AROUND_NW = 2;
const int RIVER_DIRECTION_CORNER_AROUND_NE = 3;
const int RIVER_DIRECTION_CORNER_AROUND_SW = 4;
const int RIVER_DIRECTION_CORNER_AROUND_SE = 5;

// ---- DATA LAYOUT -----
// DATA_2.r: opacity
// DATA_2.gba: unused
// DATA_1.r: sprite type:
//   TYPE_FOOTPRINT:
//     DATA_1.g: 0=base footprint, 1=blocking collision, 2=test collision
//     DATA_1.b: 0=circle; 1=rect; 2=line, 3=triangle
//     DATA_1.a: unused
//     if line:
//       COLOR.rg: UV of p1
//       COLOR.ba: UV of p2
//     elif triangle:
//       COLOR.r: packed UV of p1
//       COLOR.g: packed UV of p2
//       COLOR.b: packed UV of p3
//       COLOR.a: unused
//     else:
//       COLOR.rgba: unused
//   TYPE_TREE, TYPE_GRASS:
//     DATA_1.gb: global UV of center (for global wind lookup)
//     DATA_1.a: wind_multiplier
//     COLOR.rgba: atlas pixel frame rect
//   TYPE_TREE_DAUB_*, TYPE_GRASS_DAUB_*:
//     DATA_1.gb: global UV of center (for global wind lookup)
//     DATA_1.a: sprite-local y of center -> used for sway amount
//     COLOR.r: wind multiplier
//     COLOR.g: unused
//     COLOR.ba: grass/tree atlas pixel frame size
//   TYPE_MOUNTAIN, TYPE_HILL, TYPE_DUNE, TYPE_GLASS:
//     DATA_1.gba: unused
//     COLOR.rgba: atlas pixel frame rect
//     texture.r: lines
//     texture.g: shadows
//     texture.b: highlight
//     texture.a: opacity
//   TYPE_GENERIC:
//     DATA_1.g: atlas choice:
//        0: vegetation
//        1: building
//        2: mountain
//        3: water features
//     DATA_1.b: use line noise (0/1)
//     DATA_1.a: unused
//     COLOR.rgba: atlas pixel frame rect
//   TYPE_DAUB_GENERIC:
//     DATA_1.gba: unused
//     COLOR.rgba: daub color
//   TYPE_GRASS_DAUB_*:
//     DATA_1.gb: global UV of center (for global wind lookup)
//     DATA_1.a: sprite-local y of center (unused)
//     COLOR.rgba: atlas pixel frame rect
//   TYPE_RIVER:
//     DATA_1.g: direction type (RIVER_DIRECTION_*)
//     DATA_1.ba: global UV of center (for shard SDF lookup)
//     COLOR.rgba: atlas pixel frame rect
//     texture.r: outline
//     texture.g: wave line
//     texture.b: flow gradient
//     texture.a: opacity
//   TYPE_SEA_WAVES:
//     DATA_1.gb: global UV of center (for noise lookup)
//     DATA_1.a: unused
//     COLOR.rgba: atlas pixel frame rect
//   TYPE_LAKE:
//     DATA_1.gba: unused
//     COLOR.rgba: atlas pixel frame rect
//     texture.r: lines
//     texture.g: embankment background
//     texture.b: unused
//     texture.a: opacity
//   TYPE_SWAMP_POND:
//     DATA_1.gba: unused
//     COLOR.rgba: atlas pixel frame rect
//     texture.r: lines
//     texture.g: inside shading
//     texture.b: outside shading
//     texture.a: water
//   TYPE_BUILDING:
//     DATA_1.gba: unused
//     COLOR.rgba: atlas pixel frame rect
//     texture.r: roof
//     texture.g: lines
//     texture.b: walls
//     texture.a: shade
//   TYPE_WATERFALL:
//     DATA_1.g: unused
//     DATA_1.ba: global UV of center (for shard SDF lookup)
//     COLOR.rgba: atlas pixel frame rect
//     texture.rgb: unused
//     texture.a: opacity

#include "res://visuals/shaders/utils.gdshaderinc"
#include "res://visuals/shaders/noise.gdshaderinc"
#include "res://visuals/shaders/sdf.gdshaderinc"
#include "res://visuals/shaders/wind.gdshaderinc"
#include "res://visuals/shaders/packing.gdshaderinc"

group_uniforms dynamic;
uniform float global_opacity : hint_range(0, 1) = 1.0;
uniform sampler2D custom_data_texture: filter_nearest, repeat_disable;

group_uniforms globals;
uniform uvec2 map_size;
uniform float line_noise_scale : hint_range(1, 10) = 1.5;
uniform float line_noise_smoothness : hint_range(0.01, 1.0) = 1.0;
uniform float generic_line_noise_strength : hint_range(0.01, 2.0) = 1.0;

group_uniforms atlases;
uniform sampler2D vegetation_atlas: filter_linear_mipmap_anisotropic, repeat_disable;
uniform uvec2 vegetation_atlas_size;
uniform sampler2D mountain_atlas: filter_linear_mipmap_anisotropic, repeat_disable;
uniform uvec2 mountain_atlas_size;
uniform sampler2D building_atlas: filter_linear_mipmap_anisotropic, repeat_disable;
uniform uvec2 building_atlas_size;
uniform sampler2D water_features_atlas: filter_linear_mipmap_anisotropic, repeat_disable;
uniform uvec2 water_features_atlas_size;
uniform sampler2D daub_atlas: filter_linear_mipmap_anisotropic, repeat_disable;

group_uniforms trees;
uniform vec4 tree_daub_color_fir: source_color;
uniform vec4 tree_daub_color_willow: source_color;
uniform vec4 tree_daub_color_deciduous: source_color;
uniform vec4 tree_daub_color_sakura: source_color;
uniform float tree_wind_amplitude;
uniform float tree_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms grass;
uniform float grass_wind_amplitude;
uniform vec4 flower_daub_color_1: source_color;
uniform vec4 flower_daub_color_2: source_color;
uniform vec4 flower_daub_color_3: source_color;
uniform vec4 grass_daub_color_steppe: source_color;
uniform vec4 grass_daub_color_steppe_wind: source_color;
uniform vec4 cacti_daub_color: source_color;
uniform vec4 bush_daub_color_1: source_color;
uniform vec4 bush_daub_color_2: source_color;
uniform vec4 grass_daub_color_dry: source_color;
uniform float grass_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms daubs;
uniform int daub_frames_h = 3;
uniform int daub_frames_v = 3;

group_uniforms mountains;
uniform vec3 mountain_base_color: source_color;
uniform vec4 mountain_line_color: source_color;
uniform vec4 mountain_highlight_color: source_color;
uniform vec4 mountain_shadow_color: source_color;
uniform float mountain_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms hills;
uniform vec3 hill_base_color: source_color;
uniform float hill_highlight_alpha = 0.5;
uniform float hill_shadow_alpha = 0.5;
uniform vec4 hill_line_color: source_color;
uniform float hill_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms dunes;
uniform vec3 dune_base_color: source_color;
uniform vec4 dune_line_color: source_color;
uniform vec4 dune_highlight_color: source_color;
uniform vec4 dune_shadow_color: source_color;
uniform float dune_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms glass;
uniform vec3 glass_base_color: source_color;
uniform vec4 glass_highlight_color: source_color;
uniform vec4 glass_shadow_color: source_color;
uniform float glass_opacity = 1.0;
uniform float glass_saturation = 0.2;
uniform vec2 glass_noise_scale = vec2(1);

group_uniforms river;
uniform sampler2D river_bg: filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 river_color_scale;
uniform vec3 river_line_color: source_color;
uniform sampler2D river_wave_gradient: filter_linear_mipmap_anisotropic, repeat_enable;
uniform float river_speed = 1.0;
uniform vec2 river_sprite_size = vec2(10, 10);
uniform sampler2D river_sink_sdf: filter_linear, repeat_disable;
uniform float river_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms sea;
uniform float sea_wave_speed = 1.0;

group_uniforms lake;
uniform sampler2D lake_water_noise: filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 lake_color_1: source_color;
uniform vec3 lake_color_2: source_color;
uniform float lake_line_noise_strength : hint_range(0.0, 2.0) = .957;
uniform vec2 lake_wave_speed = vec2(0, -0.5);
uniform float lake_gradient_speed = 1.2;
uniform vec4 lake_line_color: source_color;
uniform vec4 lake_embankment_color: source_color;

group_uniforms swamp_ponds;
uniform vec4 swamp_pond_shade_color: source_color;
uniform vec3 swamp_pond_water_color_1: source_color;
uniform vec3 swamp_pond_water_color_2: source_color;
uniform vec3 swamp_pond_bokashi_color: source_color;
uniform float swamp_pond_bokashi_power = 1.2;
uniform vec4 swamp_pond_line_color: source_color;
uniform float swamp_pond_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms buildings;
uniform vec3 building_base_color: source_color;
uniform vec3 building_spackle_color: source_color;
uniform vec4 building_line_color: source_color;
uniform vec4 building_shade_color: source_color;
uniform float building_line_noise_strength : hint_range(0.0, 2.0) = .957;

group_uniforms waterfall;
uniform sampler2D waterfall_mask: filter_linear_mipmap_anisotropic, repeat_enable;
uniform float waterfall_top_highlight = 0.5;
uniform vec2 waterfall_top_highlight_size = vec2(0, 0.05);

group_uniforms debug;
uniform bool debug_wind = false;

uniform bool preview = false;
uniform bool invalid_highlight = false;

varying flat int instance_random;
varying vec4 custom_data;
varying float custom_opacity;
varying vec2 world_coord;

float line_noise(float strength) {
	float value_noise = brush_noise(world_coord * line_noise_scale, line_noise_smoothness);
	return 1.0 - clamp(value_noise * strength, 0, 1);
}

// Debug footprints

vec4 fragment_debug_footprint(vec2 full_uv, int collision_type, int shape_type, vec4 shape_data) {
	vec3 color = vec3(0., 0., 0.);
	if (collision_type == 0) {
		color = vec3(1., 0., 0.);
	} else if (collision_type == 1) {
		color = vec3(0., 1., 0.);
	} else if (collision_type == 2) {
		color = vec3(0., 0., 1.);
	}

	float alpha = 1.0;
	if (shape_type == 0) {
		// Circle.
		float dist = sdf_circle(full_uv - 0.5, 0.5);
		float dist2 = sdf_circle(full_uv - 0.5, 0.03);
		alpha = smoothstep(0.01, -0.01, dist) * 0.8 + smoothstep(0.01, -0.01, dist2);
	} else if (shape_type == 1) {
		// Leave the alpha full.
	} else if (shape_type == 2) {
		// Line.
		vec2 p1_uv = shape_data.rg;
		vec2 p2_uv = shape_data.ba;
		alpha = 0.0;
		alpha += smoothstep(0.01, -0.01, sdf_circle(full_uv - p1_uv, 0.03));
		alpha += smoothstep(0.01, -0.01, sdf_circle(full_uv - p2_uv, 0.03));
		alpha += smoothstep(0.04, 0.03, sdf_line(full_uv, p1_uv, p2_uv));
	} else if (shape_type == 3) {
		// Triangle.
		vec2 p1_uv = unpack_vec2(shape_data.r);
		vec2 p2_uv = unpack_vec2(shape_data.g);
		vec2 p3_uv = unpack_vec2(shape_data.b);

		alpha = 0.0;
		alpha += smoothstep(0.01, -0.01, sdf_circle(full_uv - p1_uv, 0.03));
		alpha += smoothstep(0.01, -0.01, sdf_circle(full_uv - p2_uv, 0.03));
		alpha += smoothstep(0.01, -0.01, sdf_circle(full_uv - p3_uv, 0.03));
		alpha += smoothstep(0.04, 0.03, sdf_triangle(full_uv, p1_uv, p2_uv, p3_uv));
	}
	return vec4(color, alpha * 0.3);
}

// Trees

vec2 vertex_tree(vec2 vertex, vec2 full_uv, vec2 atlas_frame_size, vec2 global_center, float wind_multiplier) {
	vec2 uv_rect = vec2(atlas_frame_size.x / float(vegetation_atlas_size.x),
					   atlas_frame_size.y / float(vegetation_atlas_size.y));
	float height_factor = (1.0 - full_uv.y) * uv_rect.y;
	float width_factor = 1.0 / uv_rect.x;
	vertex.x -= get_wind(global_center) * height_factor * width_factor * tree_wind_amplitude * wind_multiplier;
	return vertex;
}

vec2 vertex_tree_daub(vec2 vertex, vec2 global_center, vec2 tree_atlas_frame_size, float y_dist, float wind_multiplier) {
	vec2 uv_rect = vec2(tree_atlas_frame_size.x / float(vegetation_atlas_size.x),
					   tree_atlas_frame_size.y / float(vegetation_atlas_size.y));
	float height_factor = (1.0 - y_dist) * uv_rect.y;
	float width_factor = 1.0 / uv_rect.x;
	vertex.x -= get_wind(global_center) * height_factor * width_factor * tree_wind_amplitude * wind_multiplier;
	return vertex;
}

vec4 fragment_tree(vec2 full_uv, vec4 atlas_frame_rect) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(vegetation_atlas_size.x),
					   atlas_frame_rect.y / float(vegetation_atlas_size.y),
					   atlas_frame_rect.z / float(vegetation_atlas_size.x),
					   atlas_frame_rect.w / float(vegetation_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 color = texture(vegetation_atlas, uv);
	color.a *= line_noise(tree_line_noise_strength);
	return color;
}

// Daubs

vec4 fragment_daub(vec2 full_uv, vec4 daub_color) {
	float random = value_noise_1_1(float(instance_random));
	int frame_index = int(random * float(daub_frames_h * daub_frames_v));
	int frame_x = frame_index % daub_frames_h;
	int frame_y = frame_index / daub_frames_h;
	vec2 frame_offset = vec2(float(frame_x) / float(daub_frames_h),
							float(frame_y) / float(daub_frames_v));
	vec2 frame_uv = full_uv / vec2(float(daub_frames_h), float(daub_frames_v));
	float alpha = texture(daub_atlas, frame_offset + frame_uv).r;
	return vec4(daub_color.rgb, alpha * daub_color.a);
}

// Mountains

vec4 fragment_mountain(vec2 full_uv, vec4 atlas_frame_rect) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(mountain_atlas_size.x),
					   atlas_frame_rect.y / float(mountain_atlas_size.y),
					   atlas_frame_rect.z / float(mountain_atlas_size.x),
					   atlas_frame_rect.w / float(mountain_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(mountain_atlas, uv);
	vec3 color = mountain_base_color;
	color = mix(color, mountain_shadow_color.rgb, sample.g * mountain_shadow_color.a);
	color = mix(color, mountain_highlight_color.rgb, sample.b * mountain_highlight_color.a);
	sample.r *= line_noise(mountain_line_noise_strength);
	color = mix(color, mountain_line_color.rgb, sample.r * mountain_line_color.a);
	return vec4(color, sample.a);
}

// Grass

vec2 vertex_grass(vec2 vertex, vec2 full_uv, vec2 grass_atlas_frame_size, vec2 global_center, float wind_multiplier) {
	vec2 uv_rect = vec2(grass_atlas_frame_size.x / float(vegetation_atlas_size.x),
					   grass_atlas_frame_size.y / float(vegetation_atlas_size.y));
	float height_factor = remap(full_uv.y, 0.0, 0.8, uv_rect.y, 0);
	float remapped_wind = remap(get_wind(global_center), 0.0, 1.0, -0.5, 1.0);
	vertex.x -= remapped_wind * height_factor * grass_wind_amplitude * wind_multiplier;
	return vertex;
}

vec2 vertex_grass_daub(vec2 vertex, vec2 global_center, vec2 grass_atlas_frame_size, float y_dist, float wind_multiplier) {
	vec2 uv_rect = vec2(grass_atlas_frame_size.x / float(vegetation_atlas_size.x),
					   grass_atlas_frame_size.y / float(vegetation_atlas_size.y));
	float height_factor = (1.0 - y_dist) * uv_rect.y;
	float remapped_wind = remap(get_wind(global_center), 0.0, 1.0, -0.5, 1.0);
	vertex.x -= remapped_wind * height_factor * grass_wind_amplitude * wind_multiplier;
	return vertex;
}

vec4 fragment_grass(vec2 full_uv, vec4 atlas_frame_rect, vec2 global_center) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(vegetation_atlas_size.x),
					   atlas_frame_rect.y / float(vegetation_atlas_size.y),
					   atlas_frame_rect.z / float(vegetation_atlas_size.x),
					   atlas_frame_rect.w / float(vegetation_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 color = texture(vegetation_atlas, uv);
	color.a *= line_noise(grass_line_noise_strength);
	return color;
}

// Hill

vec4 fragment_hill(vec2 full_uv, vec4 atlas_frame_rect) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(mountain_atlas_size.x),
					   atlas_frame_rect.y / float(mountain_atlas_size.y),
					   atlas_frame_rect.z / float(mountain_atlas_size.x),
					   atlas_frame_rect.w / float(mountain_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(mountain_atlas, uv);
	vec3 color = hill_base_color;
	color = mix(color, vec3(0), sample.g * hill_shadow_alpha);
	color = mix(color, vec3(1), sample.b * hill_highlight_alpha);
	float line_alpha = sample.r * line_noise(hill_line_noise_strength);
	color = mix(color, hill_line_color.rgb, line_alpha * hill_line_color.a);
	return vec4(color, sample.a);
}

// Generic

vec4 fragment_generic(vec2 full_uv, vec4 atlas_frame_rect, int atlas_type, bool use_line_noise) {
	vec4 color;
	switch (atlas_type) {
		case ATLAS_TYPE_VEGETATION:
			vec4 uv_rect = vec4(atlas_frame_rect.x / float(vegetation_atlas_size.x),
							   atlas_frame_rect.y / float(vegetation_atlas_size.y),
							   atlas_frame_rect.z / float(vegetation_atlas_size.x),
							   atlas_frame_rect.w / float(vegetation_atlas_size.y));
			vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
			color = texture(vegetation_atlas, uv);
			break;
		case ATLAS_TYPE_BUILDINGS:
			vec4 uv_rect = vec4(atlas_frame_rect.x / float(building_atlas_size.x),
							   atlas_frame_rect.y / float(building_atlas_size.y),
							   atlas_frame_rect.z / float(building_atlas_size.x),
							   atlas_frame_rect.w / float(building_atlas_size.y));
			vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
			color = texture(building_atlas, uv);
			break;
		case ATLAS_TYPE_MOUNTAIN:
			vec4 uv_rect = vec4(atlas_frame_rect.x / float(mountain_atlas_size.x),
							   atlas_frame_rect.y / float(mountain_atlas_size.y),
							   atlas_frame_rect.z / float(mountain_atlas_size.x),
							   atlas_frame_rect.w / float(mountain_atlas_size.y));
			vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
			color = texture(mountain_atlas, uv);
			break;
		case ATLAS_TYPE_WATER_FEATURES:
			vec4 uv_rect = vec4(atlas_frame_rect.x / float(water_features_atlas_size.x),
							   atlas_frame_rect.y / float(water_features_atlas_size.y),
							   atlas_frame_rect.z / float(water_features_atlas_size.x),
							   atlas_frame_rect.w / float(water_features_atlas_size.y));
			vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
			color = texture(water_features_atlas, uv);
			break;
		default:
			color = vec4(1.0, 0.0, 0.0, 1.0);  // ERROR
			break;
	}

	if (use_line_noise) {
		color.a *= line_noise(generic_line_noise_strength);
	}

	return color;
}

// Rivers

vec4 fragment_river(vec2 full_uv, vec4 atlas_frame_rect, int direction_type, vec2 global_center) {
	// Sample the main atlas texture.
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(water_features_atlas_size.x),
					   atlas_frame_rect.y / float(water_features_atlas_size.y),
					   atlas_frame_rect.z / float(water_features_atlas_size.x),
					   atlas_frame_rect.w / float(water_features_atlas_size.y));
	full_uv.x = clamp(full_uv.x, 0.01, 0.99);  // margin to avoid seams
	full_uv.y = clamp(full_uv.y, 0.01, 0.99);  // margin to avoid seams
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(water_features_atlas, uv);

	// Get distance to cloud.
	vec2 global_center_uv = global_center / vec2(map_size);
	vec2 sprite_size = river_sprite_size / vec2(map_size);
	vec2 global_uv = remap2(full_uv, vec2(0), vec2(1), global_center_uv - sprite_size / 2.0, global_center_uv + sprite_size / 2.0);
	float distance_to_cloud = texture(river_sink_sdf, global_uv).r;

	vec3 color;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	color = texture(river_bg, full_uv * river_color_scale).rgb;
#else
	// Get the BG UVs based on flow progress and direction type.
	float wave_progress = sample.b - TIME * river_speed;
	float bg_v = 1.0;
	if (direction_type == RIVER_DIRECTION_HORIZONTAL) {
		bg_v = full_uv.y;
	} else if (direction_type == RIVER_DIRECTION_VERTICAL) {
		bg_v = full_uv.x;
	} else if (direction_type == RIVER_DIRECTION_CORNER_AROUND_NW) {
		bg_v = length(full_uv);
	} else if (direction_type == RIVER_DIRECTION_CORNER_AROUND_NE) {
		bg_v = 1.0 - length(vec2(1.0 - full_uv.x, full_uv.y));
	} else if (direction_type == RIVER_DIRECTION_CORNER_AROUND_SW) {
		bg_v = length(vec2(full_uv.x, 1.0 - full_uv.y));
	} else if (direction_type == RIVER_DIRECTION_CORNER_AROUND_SE) {
		bg_v = 1.0 - length(vec2(1.0 - full_uv.y, 1.0 - full_uv.x));
	}

	// Set the base color to scroll a texture based on flow.
	color = texture(river_bg, (vec2(wave_progress, bg_v)) * river_color_scale).rgb;

	// Show flow lines based on flow.
	float wave = texture(river_wave_gradient, vec2(wave_progress, 0.5)).r;
	wave *= smoothstep(0.53, .55, distance_to_cloud);
	color = mix(color, river_line_color.rgb, sample.g * wave);
#endif
	// Draw the outline.
	sample.r *= line_noise(river_line_noise_strength);
	color = mix(color, river_line_color.rgb, sample.r);

	// Clip at the edge of the shard.
	float alpha = sample.a * smoothstep(0.5, .51, distance_to_cloud);

	return vec4(color, alpha);
}

// Sea Waves

vec4 fragment_sea_wave(vec2 full_uv, vec4 atlas_frame_rect, vec2 global_center) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(water_features_atlas_size.x),
					   atlas_frame_rect.y / float(water_features_atlas_size.y),
					   atlas_frame_rect.z / float(water_features_atlas_size.x),
					   atlas_frame_rect.w / float(water_features_atlas_size.y));
	float alpha_factor = smoothstep(1.0, 0.6, full_uv.y);
	full_uv.y -= clamp(sin(value_noise_1_1(float(instance_random)) * 10.0 + TIME * sea_wave_speed) * 0.5 + 0.5, 0, 1);
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 color = texture(water_features_atlas, uv);
	color.a *= alpha_factor * 0.8;
	return color;
}

// Desert Dunes

vec4 fragment_dune(vec2 full_uv, vec4 atlas_frame_rect) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(mountain_atlas_size.x),
					   atlas_frame_rect.y / float(mountain_atlas_size.y),
					   atlas_frame_rect.z / float(mountain_atlas_size.x),
					   atlas_frame_rect.w / float(mountain_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(mountain_atlas, uv);
	vec3 color = dune_base_color;
	color = mix(color, dune_shadow_color.rgb, sample.g * dune_shadow_color.a);
	color = mix(color, dune_highlight_color.rgb, sample.b * dune_highlight_color.a);
	sample.r *= line_noise(dune_line_noise_strength);
	color = mix(color, dune_line_color.rgb, sample.r * dune_line_color.a);
	return vec4(color, sample.a);
}

// Glass (mainly dunes)

vec4 fragment_glass(vec2 full_uv, vec4 atlas_frame_rect, vec2 screen_uv) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(mountain_atlas_size.x),
					   atlas_frame_rect.y / float(mountain_atlas_size.y),
					   atlas_frame_rect.z / float(mountain_atlas_size.x),
					   atlas_frame_rect.w / float(mountain_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(mountain_atlas, uv);
	vec3 color = glass_base_color;
	color = mix(color, glass_shadow_color.rgb, sample.g * glass_shadow_color.a);
	float shine_hue = texture(lake_water_noise, (full_uv - screen_uv.yx * 5.0) * glass_noise_scale).r;
	vec3 shine = hsv2rgb(vec3(shine_hue, glass_saturation, 1.0));
	color = mix(color, glass_highlight_color.rgb, sample.b * glass_highlight_color.a);
	color *= shine;
	float opacity = sample.a * mix(glass_opacity, 1.0, sample.r);
	sample.r *= line_noise(dune_line_noise_strength);
	color = mix(color, dune_line_color.rgb, sample.r * dune_line_color.a);
	return vec4(color, opacity);
}

// Lake

vec4 fragment_lake(vec2 full_uv, vec4 atlas_frame_rect) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(water_features_atlas_size.x),
					   atlas_frame_rect.y / float(water_features_atlas_size.y),
					   atlas_frame_rect.z / float(water_features_atlas_size.x),
					   atlas_frame_rect.w / float(water_features_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(water_features_atlas, uv);

	vec2 square_uv = uv * 0.5;
	square_uv.y *= atlas_frame_rect.w / atlas_frame_rect.z;
	float noise_gradient1 = texture(lake_water_noise, square_uv + TIME * lake_wave_speed / 1000.0).r;
	float noise_gradient2 = texture(lake_water_noise, square_uv + TIME * lake_wave_speed / 1000.0 + vec2(.1234, .4567)).r;
	float noise_gradient = remap(sin(TIME * lake_gradient_speed), -1, 1, noise_gradient1, noise_gradient2);
	vec3 color = mix(lake_color_1, lake_color_2, noise_gradient);

	color = mix(color, lake_embankment_color.rgb, sample.g * lake_embankment_color.a);

	sample.r *= line_noise(lake_line_noise_strength);
	color = mix(color, lake_line_color.rgb, sample.r * lake_line_color.a);

	return vec4(color, sample.a);
}

// Swamp Ponds

vec4 fragment_swamp_pond(vec2 full_uv, vec4 atlas_frame_rect) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(water_features_atlas_size.x),
					   atlas_frame_rect.y / float(water_features_atlas_size.y),
					   atlas_frame_rect.z / float(water_features_atlas_size.x),
					   atlas_frame_rect.w / float(water_features_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(water_features_atlas, uv);

	// Base / shader color.
	vec3 color = swamp_pond_shade_color.rgb;

	// Water.
	vec2 square_uv = 0.15 * uv;
	//square_uv.y *=  atlas_frame_rect.w / atlas_frame_rect.z;
	float noise_gradient1 = texture(lake_water_noise, square_uv + TIME * lake_wave_speed / 1000.0).r;
	float noise_gradient2 = texture(lake_water_noise, square_uv + TIME * lake_wave_speed / 1000.0 + vec2(.1234, .4567)).r;
	float noise_gradient = remap(sin(TIME * lake_gradient_speed), -1, 1, noise_gradient1, noise_gradient2);
	vec3 water_color = mix(swamp_pond_water_color_1, swamp_pond_water_color_2, noise_gradient);
	float water_alpha = clamp(sample.a - sample.b, 0, 1);
	color = mix(color, water_color, water_alpha);

	// Lilies.
	color = mix(color, color + swamp_pond_bokashi_color, pow(sample.g, swamp_pond_bokashi_power));

	// Lines.
	sample.r *= line_noise(swamp_pond_line_noise_strength);
	color = mix(color, swamp_pond_line_color.rgb, sample.r * swamp_pond_line_color.a);

	// Alpha / final.
	return vec4(color, sample.a - sample.b * (1.0 - swamp_pond_shade_color.a));
}

// Buildings

vec4 fragment_building(vec2 full_uv, vec4 atlas_frame_rect, vec3 roof_color) {
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(building_atlas_size.x),
					   atlas_frame_rect.y / float(building_atlas_size.y),
					   atlas_frame_rect.z / float(building_atlas_size.x),
					   atlas_frame_rect.w / float(building_atlas_size.y));
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	vec4 sample = texture(building_atlas, uv);
	vec4 color = vec4(0);

	// Shade
	float shade_alpha = clamp(sample.a - lightest(sample.rgb), 0, 1);
	color = mix(color, building_shade_color, shade_alpha);

	// Walls
	vec3 wall_color = mix(building_base_color.rgb, building_spackle_color.rgb, line_noise(building_line_noise_strength));
	float wall_alpha = sample.b * sample.a;
	color = alpha_blend(vec4(wall_color, wall_alpha), color);

	// Roof
	float roof_alpha = sample.r * sample.a * line_noise(building_line_noise_strength);
	color = alpha_blend(vec4(roof_color, roof_alpha), color);

	// Lines
	float line_alpha = sample.g * sample.a * line_noise(building_line_noise_strength);
	color = alpha_blend(vec4(building_line_color.rgb, line_alpha), color);

	return color;
}

// Rivers

vec4 fragment_waterfall(vec2 full_uv, vec4 atlas_frame_rect) {
	// Sample the main atlas texture.
	vec4 uv_rect = vec4(atlas_frame_rect.x / float(water_features_atlas_size.x),
					   atlas_frame_rect.y / float(water_features_atlas_size.y),
					   atlas_frame_rect.z / float(water_features_atlas_size.x),
					   atlas_frame_rect.w / float(water_features_atlas_size.y));
	full_uv.y = max(full_uv.y, 0.01);  // margin to avoid seams
	vec2 uv = remap2(full_uv, vec2(0), vec2(1), uv_rect.xy, uv_rect.xy + uv_rect.zw);
	float alpha = texture(water_features_atlas, uv).a;

	vec3 color = texture(river_bg, full_uv + vec2(0, -TIME * river_speed * 4.0) * river_color_scale).rgb;
	color += remap(full_uv.y, 0.0, waterfall_top_highlight_size.x, 0.0, waterfall_top_highlight)
		   * remap(full_uv.y, 0.0, waterfall_top_highlight_size.y, waterfall_top_highlight, 0.0);
	color.rg -= 0.03; // HACK: For some reason it looks lighter overall?
	vec2 mask_uv = vec2(full_uv.x, full_uv.y - TIME * river_speed * 4.0);
	mask_uv.x *= 4.0;
	alpha *= pow(1.0 - full_uv.y, 4) + texture(waterfall_mask, mask_uv).r * pow(remap(full_uv.y, 0.5, 0.95, 1.0, 0.0), 2);

	return vec4(color, alpha);
}

// Main

void vertex() {
	int base_index = INSTANCE_ID * 2;
	custom_data = texelFetch(custom_data_texture, ivec2(base_index % CUSTOM_DATA_BUFFER_WIDTH, base_index / CUSTOM_DATA_BUFFER_WIDTH), 0);
	custom_opacity = texelFetch(custom_data_texture, ivec2((base_index + 1) % CUSTOM_DATA_BUFFER_WIDTH, (base_index + 1) / CUSTOM_DATA_BUFFER_WIDTH), 0).r;

	world_coord = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; // Before wind skew, so the noise pattern doesn't shift.
	instance_random = int(MODEL_MATRIX[0][0] * 100.0 + MODEL_MATRIX[0][1] * 10000.0);

	vec2 quad_corrected_uv = vec2(UV.x, 1.0 - UV.y);
	vec2 global_center = custom_data.gb;

	int sprite_type = int(round(custom_data.r));
	switch (sprite_type) {
		case TYPE_FOOTPRINT:
			break;
		case TYPE_TREE:
			vec4 atlas_frame_rect = COLOR;
			VERTEX = vertex_tree(VERTEX, quad_corrected_uv, atlas_frame_rect.zw, global_center, custom_data.a);
			break;
		case TYPE_TREE_DAUB_FIR:
		case TYPE_TREE_DAUB_WILLOW:
		case TYPE_TREE_DAUB_DECIDUOUS:
		case TYPE_TREE_DAUB_SAKURA:
			vec4 tree_atlas_frame_rect = COLOR;
			VERTEX = vertex_tree_daub(VERTEX, global_center, COLOR.ba, custom_data.a, COLOR.r);
			break;
		case TYPE_MOUNTAIN:
		case TYPE_GENERIC:
		case TYPE_HILL_PLAINS:
		case TYPE_RIVER:
		case TYPE_SEA_WAVES:
		case TYPE_DUNE:
		case TYPE_LAKE:
		case TYPE_SWAMP_POND:
		case TYPE_DAUB_GENERIC:
			break;
		case TYPE_GRASS:
			vec4 atlas_frame_rect = COLOR;
			VERTEX = vertex_grass(VERTEX, quad_corrected_uv, atlas_frame_rect.zw, global_center, custom_data.a);
			break;
		case TYPE_GRASS_DAUB_DESERT:
		case TYPE_GRASS_DAUB_FLOWER_1:
		case TYPE_GRASS_DAUB_FLOWER_2:
		case TYPE_GRASS_DAUB_FLOWER_3:
		case TYPE_GRASS_DAUB_STEPPE:
		case TYPE_GRASS_DAUB_BUSH:
		case TYPE_GRASS_DAUB_DRY:
			vec4 grass_atlas_frame_rect = COLOR;
			VERTEX = vertex_grass_daub(VERTEX, global_center, COLOR.ba, custom_data.a, COLOR.r);
			break;
		default:  // ERROR
			break;
	}

	// Transform to world space after adjustments.
    VERTEX = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 quad_corrected_uv = vec2(UV.x, 1.0 - UV.y);
	vec2 global_center = custom_data.gb;

	int sprite_type = int(round(custom_data.r));
	float opacity = custom_opacity;
	if (debug_wind) {
		COLOR = vec4(get_wind(global_center), 0., 0., 1.);
	} else {
		switch (sprite_type) {
			case TYPE_FOOTPRINT:
				int collision_type = int(custom_data.g);
				int shape_type = int(custom_data.b);
				vec2 p1_uv = COLOR.rg;
				vec2 p2_uv = COLOR.ba;
				COLOR = fragment_debug_footprint(quad_corrected_uv, collision_type, shape_type, COLOR);
				opacity = 1.0; // Does not use per-instance opacity.
				break;
			case TYPE_TREE:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_tree(quad_corrected_uv, atlas_frame_rect);
				break;
			case TYPE_TREE_DAUB_FIR:
				COLOR = fragment_daub(quad_corrected_uv, tree_daub_color_fir);
				break;
			case TYPE_TREE_DAUB_WILLOW:
				COLOR = fragment_daub(quad_corrected_uv, tree_daub_color_willow);
				break;
			case TYPE_TREE_DAUB_DECIDUOUS:
				COLOR = fragment_daub(quad_corrected_uv, tree_daub_color_deciduous);
				break;
			case TYPE_TREE_DAUB_SAKURA:
				COLOR = fragment_daub(quad_corrected_uv, tree_daub_color_sakura);
				break;
			case TYPE_MOUNTAIN:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_mountain(quad_corrected_uv, atlas_frame_rect);
				break;
			case TYPE_GRASS:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_grass(quad_corrected_uv, atlas_frame_rect, global_center);
				break;
			case TYPE_GRASS_DAUB_DESERT:
				COLOR = fragment_daub(quad_corrected_uv, cacti_daub_color);
				break;
			case TYPE_GRASS_DAUB_FLOWER_1:
				COLOR = fragment_daub(quad_corrected_uv, flower_daub_color_1);
				break;
			case TYPE_GRASS_DAUB_FLOWER_2:
				COLOR = fragment_daub(quad_corrected_uv, flower_daub_color_2);
				break;
			case TYPE_GRASS_DAUB_FLOWER_3:
				COLOR = fragment_daub(quad_corrected_uv, flower_daub_color_3);
				break;
			case TYPE_GRASS_DAUB_STEPPE:
				COLOR = fragment_daub(quad_corrected_uv, mix(grass_daub_color_steppe, grass_daub_color_steppe_wind, pow(get_wind(global_center) * 1.3, 1.5)));
				break;
			case TYPE_GRASS_DAUB_BUSH:
				float color_random = value_noise_1_1(float(instance_random));
				vec4 bush_daub_color = vec4(
					hsv2rgb(mix(rgb2hsv(bush_daub_color_1.rgb), rgb2hsv(bush_daub_color_2.rgb), color_random)),
					mix(bush_daub_color_1.a, bush_daub_color_2.a, value_noise_1_1(float(instance_random + 123))));
				COLOR = fragment_daub(quad_corrected_uv, bush_daub_color);
				break;
			case TYPE_HILL_PLAINS:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_hill(quad_corrected_uv, atlas_frame_rect);
				break;
			case TYPE_GENERIC:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_generic(quad_corrected_uv, atlas_frame_rect, int(custom_data.g), custom_data.b > 0.5);
				break;
			case TYPE_RIVER:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_river(quad_corrected_uv, atlas_frame_rect, int(custom_data.g), custom_data.ba);
				break;
			case TYPE_SEA_WAVES:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_sea_wave(quad_corrected_uv, atlas_frame_rect, custom_data.gb);
				break;
			case TYPE_DUNE:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_dune(quad_corrected_uv, atlas_frame_rect);
				break;
			case TYPE_GLASS:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_glass(quad_corrected_uv, atlas_frame_rect, SCREEN_UV);
				break;
			case TYPE_LAKE:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_lake(quad_corrected_uv, atlas_frame_rect);
				break;
			case TYPE_SWAMP_POND:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_swamp_pond(quad_corrected_uv, atlas_frame_rect);
				break;
			case TYPE_DAUB_GENERIC:
				COLOR = fragment_daub(quad_corrected_uv, COLOR);
				break;
			case TYPE_GRASS_DAUB_DRY:
				COLOR = fragment_daub(quad_corrected_uv, grass_daub_color_dry);
				break;
			case TYPE_BUILDING:
				vec4 atlas_frame_rect = COLOR;
				vec3 roof_color = custom_data.gba;
				COLOR = fragment_building(quad_corrected_uv, atlas_frame_rect, roof_color);
				break;
			case TYPE_WATERFALL:
				vec4 atlas_frame_rect = COLOR;
				COLOR = fragment_waterfall(quad_corrected_uv, atlas_frame_rect);
				break;
			default:  // ERROR
				COLOR = vec4(1., 0., 0., 1.);
				break;
		}
	}

	if (opacity <= 1.0) {
		float transition_gradient = texture(waterfall_mask, UV / 5.0).r;
		COLOR.a *= smoothstep(opacity * 1.2, opacity * 1.2 - 0.2, transition_gradient);
	} else if (opacity <= 2.0) {
		float transition_gradient = texture(waterfall_mask, UV / 5.0).r;
		opacity = 2.0 - opacity;
		COLOR.a *= smoothstep(opacity * 1.2, opacity * 1.2 - 0.2, 1.0 - transition_gradient);
	}
	COLOR.a *= global_opacity;

	if (preview) {
		COLOR.a *= 0.7;
	}
	if (invalid_highlight) {
		COLOR.rgb *= vec3(1.0, 0.5, 0.5);
	}
}
