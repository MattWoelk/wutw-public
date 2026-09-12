@tool
class_name MapExperiment1
extends PanelContainer

@export var clip_sdf_array: PackedByteArray
@export var dupe_decay: float = 0.8
@export var randomize_seed: bool
@export var random_seed: int

@export_group("Fill")
@export var placer_configs: Dictionary[TextureRect, MapSpritePlacerConfig]
@export_tool_button('Fill Biomes') @warning_ignore('unused_private_class_variable')
var _fill_biomes_tool := _fill_biomes

@export_group("Single")
@export var single_sprite_types: Array[MapSpriteType]
@export var single_coord: Vector2 = Vector2(300, 150)
@export_tool_button('Place Single') @warning_ignore('unused_private_class_variable')
var _place_single_tool := _place_single

@export_group("Clump")
@export var clump_sprite_types: Array[MapSpriteType]
@export var clump_coord: Vector2 = Vector2(300, 150)
@export var clump_count: int = 5
@export var clump_max_distance: float = 10.0
@export var clump_packing_factor: float = 0.2
@export var clump_spacing_multiplier: float = 1.0
@export_tool_button('Place Clump') @warning_ignore('unused_private_class_variable')
var _place_clump_tool := _place_clump

@export_group("Clear")
@export_tool_button('Clear') @warning_ignore('unused_private_class_variable')
var _clear_tool := _clear

@export_group("Animate")
@export var removed_index: int = 0
@export var added_placement: MapSpritePlacement
@export_tool_button('Animate Add') @warning_ignore('unused_private_class_variable')
var _fill_animate_add := _animate_add
@export_tool_button('Animate Remove') @warning_ignore('unused_private_class_variable')
var _fill_animate_remove := _animate_remove

var _placer: MapSpritePlacer

func ready() -> void:
	_reinitialize()

func _clear() -> void:
	(%MapSpriteRenderer as MapSpriteRenderer).placements = []

func _reinitialize() -> void:
	if randomize_seed:
		random_seed = randi_range(0, 10000)

	var map_size := Vector2i(455, 256)
	var sdf_range := 50.0

	var quad_tree := QuadTree.new()
	quad_tree.initialize(Rect2(Vector2(0, 0), map_size));
	_placer = MapSpritePlacer.new()
	_placer.initialize(map_size, clip_sdf_array, sdf_range, quad_tree, dupe_decay, random_seed, false)

func _fill_biomes() -> void:
	_reinitialize()

	_clear()
	for biome_node in placer_configs:
		var image := (biome_node.texture as Texture2D).get_image()
		var sdf_array: PackedByteArray
		sdf_array.resize(image.get_width() * image.get_height())
		for y in image.get_height():
			for x in image.get_width():
				sdf_array[y * image.get_width() + x] = image.get_pixel(x, y).r8

		var placements := _placer.fill_biome(sdf_array, placer_configs[biome_node])
		print(placements.size())
		(%MapSpriteRenderer as MapSpriteRenderer).placements += placements

	var qt := QuadTree.new()
	qt.initialize(Rect2(0, 0, 100, 100))
	qt.add_triangle(self, Vector2(0, 0), Vector2(50, 50), Vector2(0, 50), true)
	print('should not: ', qt.intersects_line(Vector2(1, 0), Vector2(10, 0), true))
	print('should: ', qt.intersects_line(Vector2(0, 5), Vector2(10, 5), true))

func _place_single() -> void:
	_reinitialize()

	var placement := _placer.place_single_from_pool(single_sprite_types, single_coord)
	(%MapSpriteRenderer as MapSpriteRenderer).placements += [placement]

func _place_clump() -> void:
	_reinitialize()

	var placements := _placer.place_clump(
		clump_sprite_types, clump_coord, clump_count,
		clump_max_distance, clump_packing_factor, clump_spacing_multiplier)
	(%MapSpriteRenderer as MapSpriteRenderer).placements += placements

func _animate_add() -> void:
	var renderer := %MapSpriteRenderer_DEBUG as MapSpriteRenderer
	renderer.animate_add_placement(added_placement)

func _animate_remove() -> void:
	var renderer := %MapSpriteRenderer_DEBUG as MapSpriteRenderer
	renderer.animate_remove_placement(renderer.placements[removed_index])
