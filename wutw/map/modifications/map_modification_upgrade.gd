class_name MapModification_Upgrade
extends MapModification

var location: Vector2
var radius: float
var biome: MapBiomes.Biome
var old_sprite_type: MapSpriteType
var new_sprite_type: MapSpriteType
var extra_removables: Array[MapSpriteType]
var roof_color_override: Color = Color.TRANSPARENT

func apply(map: Map, _animate: bool = true) -> bool:
	Utils.ensure(not new_sprite_type.resource_path.is_empty())  # Must be reloadable.
	_setup_random(map, location)

	var effective_new_sprite_type := _replace_roof_color(new_sprite_type, roof_color_override)

	var placer := map.generated_map.sprite_placer
	var renderer := map.get_sprite_renderer()
	var sdf := map.generated_map.raw_biome_sdfs[biome] if biome else PackedByteArray()

	var qt := map.generated_map.sprites_quad_tree
	var all_existing := qt.query_circle(location, radius, false)
	for existing: MapSpritePlacement in all_existing:
		if existing.sprite_type.is_canonically_equal(old_sprite_type):
			# First try to replace exactly.
			var can_replace_exactly := true
			var to_remove: Array[MapSpritePlacement]
			for intersecting in placer.get_intersecting_sprites(effective_new_sprite_type, existing.location, existing.scale):
				if intersecting != existing:
					if intersecting.sprite_type.removable or intersecting.sprite_type in extra_removables:
						to_remove.append(intersecting)
					else:
						can_replace_exactly = false
						break
			# HACK: Sea upgrades risk straying outside the sea since we're not doing biome checks.
			if biome == MapBiomes.Biome.SEA:
				can_replace_exactly = false
			if can_replace_exactly:
				qt.remove(existing)
				renderer.animate_remove_placement(existing)
				var replaced := placer.place_single(effective_new_sprite_type, existing.location, existing.scale)
				renderer.animate_add_placement(replaced)
				for intersecting in to_remove:
					qt.remove(intersecting)
					renderer.animate_remove_placement(intersecting)
				return true

			# If can't replace exactly, try removing the existing and placing the new.
			qt.remove(existing)  # Trial!
			# TODO: Preserve scale relative to default.
			var placed := await _threaded_try_place_single(map, effective_new_sprite_type, sdf, location, radius, extra_removables, biome == MapBiomes.Biome.SEA)
			if placed:
				renderer.animate_remove_placement(existing)
				for intersecting in placer.get_intersecting_sprites(effective_new_sprite_type, placed.location, placed.scale):
					if intersecting != placed:
						qt.remove(intersecting)
						renderer.animate_remove_placement(intersecting)
				renderer.animate_add_placement(placed)
				return true
			else:
				# Failed. Recreate the original.
				renderer.remove_placement(existing)
				renderer.add_placement(placer.place_single(existing.sprite_type, existing.location, existing.scale))
	if Utils.is_dev():
		push_warning('Failed to upgrade sprite to: ', new_sprite_type.resource_path)
	return false

func _encode_args() -> Dictionary:
	return {
		'location': [location.x, location.y],
		'radius': radius,
		'biome': biome as int,
		'old_sprite_type': old_sprite_type.resource_path,
		'new_sprite_type': new_sprite_type.resource_path,
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
	biome = encoded['biome']
	old_sprite_type = load(encoded['old_sprite_type'] as String)
	new_sprite_type = load(encoded['new_sprite_type'] as String)
	extra_removables = []
	for removable_path: String in encoded['extra_removables']:
		extra_removables.append(load(removable_path))
	var encoded_roof_color: Array = encoded.get('roof_color_override', [0, 0, 0, 0])
	roof_color_override = Color(encoded_roof_color[0] as float,
								encoded_roof_color[1] as float,
								encoded_roof_color[2] as float,
								encoded_roof_color[3] as float)
