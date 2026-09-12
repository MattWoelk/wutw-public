class_name MapModification_AttachToRiver  # OrLake
extends MapModification

var location: Vector2
var radius: float
var sprite_type: MapSpriteType
var replaced_sprite_type: MapSpriteType
var keep_replaced: bool = false
var ignored_colliders: Array[MapSpriteType]
var roof_color_override: Color = Color.TRANSPARENT

func apply(map: Map, _animate: bool = true) -> bool:
	Utils.ensure(not sprite_type.resource_path.is_empty())  # Must be reloadable.
	_setup_random(map, location)

	var effective_sprite_type := _replace_roof_color(sprite_type, roof_color_override)

	var placer := map.generated_map.sprite_placer
	var qt := map.generated_map.sprites_quad_tree
	var renderer := map.get_sprite_renderer()

	for existing: MapSpritePlacement in qt.query_circle(location, radius, false):
		var river_sprite := existing.sprite_type as MapSpriteType_River
		var lake_sprite := existing.sprite_type as MapSpriteType_Lake
		var slots: Array[MapSpriteComponent]
		var scale_factor := 1.0
		if river_sprite:
			# Base sprite scale already taken into account for rivers.
			slots = river_sprite.slots
		elif lake_sprite:
			# Base sprite scale *not* taken into account for lakes because they were resized later.
			slots = lake_sprite.slots
			scale_factor = existing.scale
		else:
			continue

		if replaced_sprite_type:
			if not existing.used_by or not existing.used_by.sprite_type.is_canonically_equal(replaced_sprite_type):
				continue
		else:
			if existing.used_by:
				continue

		for slot in slots:
			if not slot.sprite_type.is_canonically_equal(effective_sprite_type):
				continue
			var target_location := existing.location + slot.offset * scale_factor
			var scale := slot.scale * effective_sprite_type.default_scale * scale_factor
			var blocked := false
			var to_remove: Array[MapSpritePlacement]
			for intersecting in placer.get_intersecting_sprites(effective_sprite_type, target_location, scale):
				if intersecting.sprite_type.removable:
					to_remove.append(intersecting)
				elif intersecting.sprite_type in ignored_colliders:
					continue
				elif river_sprite and intersecting.sprite_type is MapSpriteType_River:
					# Can't be in ignored_colliders because it's duplicated when placed.
					continue
				elif lake_sprite and intersecting.sprite_type is MapSpriteType_Lake:
					# Can't be in ignored_colliders because it's duplicated when placed.
					continue
				else:
					blocked = true
					break
			if blocked:
				continue
			var placed := placer.place_single(effective_sprite_type, target_location, scale)
			renderer.animate_add_placement(placed)
			for removed in to_remove:
				qt.remove(removed)
				renderer.animate_remove_placement(removed)
			if existing.used_by and not keep_replaced:
				renderer.animate_remove_placement(existing.used_by)
			existing.used_by = placed
			return true

	return false

func _encode_args() -> Dictionary:
	return {
		'location': [location.x, location.y],
		'radius': radius,
		'sprite_type': sprite_type.resource_path,
		'keep_replaced': keep_replaced,
		'replaced_sprite_type': replaced_sprite_type.resource_path if replaced_sprite_type else '',
		'ignored_colliders': ignored_colliders.map(func(x: MapSpriteType) -> String: return x.resource_path),
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
	sprite_type = load(encoded['sprite_type'] as String)
	var replaced_sprite_type_path := encoded['replaced_sprite_type'] as String
	replaced_sprite_type = load(replaced_sprite_type_path) if replaced_sprite_type_path else null
	keep_replaced = encoded['keep_replaced']
	ignored_colliders = []
	for ignored_path: String in encoded['ignored_colliders']:
		ignored_colliders.append(load(ignored_path))
	var encoded_roof_color: Array = encoded.get('roof_color_override', [0, 0, 0, 0])
	roof_color_override = Color(encoded_roof_color[0] as float,
								encoded_roof_color[1] as float,
								encoded_roof_color[2] as float,
								encoded_roof_color[3] as float)
