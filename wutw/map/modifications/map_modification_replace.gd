class_name MapModification_Replace
extends MapModification

var location: Vector2
var radius: float
var old_sprite_types: Array[MapSpriteType]
var new_sprite_type: MapSpriteType
var offset: Vector2
var leave_original: bool
var extra_removables: Array[MapSpriteType]
var roof_color_override: Color = Color.TRANSPARENT

func apply(map: Map, _animate: bool = true) -> bool:
	Utils.ensure(not new_sprite_type.resource_path.is_empty())  # Must be reloadable.
	_setup_random(map, location)

	var effective_new_sprite_type := _replace_roof_color(new_sprite_type, roof_color_override)

	# Collect potential matching types.
	var existing_by_index: Dictionary[int, Array]  # Array[MapSpritePlacement]
	var qt := map.generated_map.sprites_quad_tree
	for existing: MapSpritePlacement in qt.query_circle(location, radius, false):
		for i in old_sprite_types.size():
			if old_sprite_types[i].is_canonically_equal(existing.sprite_type):
				if i not in existing_by_index:
					existing_by_index[i] = []
				existing_by_index[i].append(existing)
				break

	# Try in order of preference.
	var placer := map.generated_map.sprite_placer
	for index in range(old_sprite_types.size()):
		for existing: MapSpritePlacement in existing_by_index.get(index, []):
			var any_conflicting := false
			var relative_scale := existing.scale / existing.sprite_type.default_scale
			var all_intersecting := placer.get_intersecting_sprites(effective_new_sprite_type, existing.location + offset, relative_scale)
			for intersecting in all_intersecting:
				if intersecting == existing:  # Don't care about canonicity, since we are comparing to ones on the map.
					continue
				elif intersecting.sprite_type.removable:
					continue
				elif intersecting.sprite_type in extra_removables:
					continue
				else:
					any_conflicting = true
					break
			if not any_conflicting:
				# Found a valid placement!
				var placed := placer.place_single(effective_new_sprite_type, existing.location + offset, relative_scale)
				if placed:
					var renderer := map.get_sprite_renderer()
					renderer.animate_add_placement(placed)
					for intersecting in all_intersecting:
						if (not leave_original and intersecting == existing or
								intersecting.sprite_type.removable or
								intersecting.sprite_type in extra_removables):
							qt.remove(intersecting)
							renderer.animate_remove_placement(intersecting)
					return true
				else:
					if Utils.is_dev():
						push_warning('Failed to place sprite: ', new_sprite_type.resource_path)

	return false

func _encode_args() -> Dictionary:
	return {
		'location': [location.x, location.y],
		'radius': radius,
		'old_sprite_types': old_sprite_types.map(func(x: MapSpriteType) -> String: return x.resource_path),
		'new_sprite_type': new_sprite_type.resource_path,
		'offset': [offset.x, offset.y],
		'leave_original': leave_original,
		'extra_removables': extra_removables.map(func(x: MapSpriteType) -> String: return x.resource_path),
		'roof_color_override': [
			roof_color_override.r,
			roof_color_override.g,
			roof_color_override.b,
			roof_color_override.a
		],
	}

func _decode_args(encoded: Dictionary) -> void:
	location.x = encoded['location'][0]
	location.y = encoded['location'][1]
	radius = encoded['radius']
	old_sprite_types = []
	for old_path: String in encoded['old_sprite_types']:
		old_sprite_types.append(load(old_path))
	new_sprite_type = load(encoded['new_sprite_type'] as String)
	offset.x = encoded['offset'][0]
	offset.y = encoded['offset'][1]
	leave_original = encoded['leave_original']
	extra_removables = []
	for removable_path: String in encoded['extra_removables']:
		extra_removables.append(load(removable_path))
	var encoded_roof_color: Array = encoded.get('roof_color_override', [0, 0, 0, 0])
	roof_color_override = Color(encoded_roof_color[0] as float,
								encoded_roof_color[1] as float,
								encoded_roof_color[2] as float,
								encoded_roof_color[3] as float)
