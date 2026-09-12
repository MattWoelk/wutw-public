@tool
class_name MapRoadManager
extends Node2D

static var ROAD_SCENE := AsyncLoadedResource.new('res://map/roads/road.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var map: Map:
	set(value):
		if map == value:
			return
		map = value
		if not map:
			clear()

var _roads: Array[Road]
var _waiting: bool = false

func create_new_road(src: Vector2, src_radius: float, dst: Vector2, dst_radius: float, skip_animation: bool = false) -> Road:
	assert(map and map.generated_map and map.generated_map.road_creator)

	while _waiting:
		await get_tree().process_frame

	var thread := Thread.new()
	_waiting = true
	thread.start(_pathfind.bind(src, src_radius, dst, dst_radius))
	while _waiting:
		await get_tree().process_frame

	var points := thread.wait_to_finish() as PackedVector2Array
	if points.is_empty():
		if Utils.is_dev():
			push_warning('Could not find road path from %s to %s.' % [src, dst])
		return null

	# Remove points that are in the sea.
	for i in range(points.size() - 1, -1, -1):
		if map.get_biome_at_position(points[i]) == MapBiomes.SEA:
			points.remove_at(i)

	var road := ROAD_SCENE.instantiate_loaded_scene() as Road
	road.map = map
	road.points = points
	road.skip_animation = skip_animation
	add_road(road)
	road.owner = owner
	return road

func add_road(road: Road) -> void:
	add_child(road)
	_roads.append(road)

func remove_road(road: Road) -> void:
	remove_child(road)
	_roads.erase(road)

func clear() -> void:
	Utils.clear_node(self)
	_roads.clear()

func _pathfind(src: Vector2, src_radius: float, dst: Vector2, dst_radius: float) -> PackedVector2Array:
	assert(map and map.generated_map and map.generated_map.road_creator)
	var result := map.generated_map.road_creator.find_road(src, src_radius, dst, dst_radius)
	_waiting = false
	return result
