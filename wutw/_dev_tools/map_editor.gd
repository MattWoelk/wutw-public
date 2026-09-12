@tool
class_name MapEditor
extends Map

@export_group('DEBUG: Fill')
@export var fill_circle_placer_config: MapSpritePlacerConfig
@export var fill_coord: Vector2 = Vector2(300, 150)
@export var fill_radius: int = 14
@export var fill_animate: bool = false
@export_tool_button('Fill Circle') @warning_ignore('unused_private_class_variable')
var _fill_circle_tool := _fill_circle

@export_group('DEBUG: Try Place')
@export var try_place_sprite_type: MapSpriteType
@export var try_place_coord: Vector2 = Vector2(300, 150)
@export var try_place_biome: MapBiomes.Biome
@export var try_place_radius: int = 14
@export var try_place_clip_margin: float = 2.0
@export_tool_button('Try Place') @warning_ignore('unused_private_class_variable')
var _try_place_tool := _try_place

@export_group('DEBUG: Roads')
@export var road_marker_sprite: MapSpriteType
@export var road_src_radius: float = 14
@export var road_dst_radius: float = 5
@export_tool_button('Find road') @warning_ignore('unused_private_class_variable')
var _find_road_tool := _find_road
@export_tool_button('Clear all roads') @warning_ignore('unused_private_class_variable')
var _find_clear_roads := _clear_roads

@export_group('DEBUG: Test Clip')
@export var test_clip_sprite_type: MapSpriteType
@export var test_clip_coord: Vector2 = Vector2(300, 150)
@export var test_clip_scale: float = 1.0
@export var test_clip_margin: float = 1.0
@export_tool_button('Test Clip') @warning_ignore('unused_private_class_variable')
var _test_clip_tool := _test_clip

func _fill_circle() -> void:
	var mod := MapModification_Fill.new()
	mod.location = fill_coord
	mod.radius = fill_radius
	mod.config = fill_circle_placer_config
	await mod.apply_fill(self, fill_animate)

func _try_place() -> void:
	var mod := MapModification_Place.new()
	mod.sprite_type = try_place_sprite_type
	mod.location = try_place_coord
	mod.biome = try_place_biome
	mod.radius = try_place_radius
	mod.clip_margin = try_place_clip_margin
	mod.apply(self)

func _find_road() -> void:
	var mod := MapModification_Road.new()
	mod.src = (%RoadSrc as Control).position
	mod.src_radius = road_src_radius
	mod.dst = (%RoadDst as Control).position
	mod.dst_radius = road_dst_radius
	mod.apply(self)

func _test_clip() -> void:
	var placer := generated_map.sprite_placer
	print('CLIP TEST RESULT: ', placer.debug_passes_clip(test_clip_sprite_type, test_clip_coord, test_clip_scale, test_clip_margin))

func _clear_roads() -> void:
	(%MapRoadManager as MapRoadManager).clear()
