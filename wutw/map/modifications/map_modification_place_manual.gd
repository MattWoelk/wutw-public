class_name MapModification_PlaceManual
extends MapModification

var location: Vector2
var sprite_type: MapSpriteType

func apply(map: Map, _animate: bool = true) -> bool:
	Utils.ensure(not sprite_type.resource_path.is_empty())  # Must be reloadable.

	var qt := map.generated_map.sprites_quad_tree
	var placer := map.generated_map.sprite_placer
	var placed := placer.place_single(sprite_type, location)
	if Utils.ensure(placed != null):
		for intersecting in placer.get_intersecting_sprites(sprite_type, location):
			if intersecting != placed:
				qt.remove(intersecting)
				map.get_sprite_renderer().animate_remove_placement(intersecting)
		map.get_sprite_renderer().animate_add_placement(placed)
		return true
	else:
		return false

func _encode_args() -> Dictionary:
	return {
		'location': [location.x, location.y],
		'sprite_type': sprite_type.resource_path,
	}

func _decode_args(encoded: Dictionary) -> void:
	location.x = encoded['location'][0]
	location.y = encoded['location'][1]
	sprite_type = load(encoded['sprite_type'] as String)
