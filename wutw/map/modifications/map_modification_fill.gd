class_name MapModification_Fill
extends MapModification

var location: Vector2
var radius: int
var config: MapSpritePlacerConfig
var min_sprites: int = 3
var fallback_removable_sprites: Array[MapSpriteType]
var roof_color_override: Color = Color.TRANSPARENT

const MAX_ANIM_TIME := 3.0

func apply(map: Map, animate: bool = false) -> bool:
	Utils.ensure(not config.resource_path.is_empty())  # Must be reloadable.
	_setup_random(map, location)

	# Replace roof color.
	var effective_config := config
	if roof_color_override.a > 0.5:
		effective_config = effective_config.duplicate()
		effective_config.sprite_types = effective_config.sprite_types.duplicate()
		for i in effective_config.sprite_types.size():
			effective_config.sprite_types[i] = _replace_roof_color(
				effective_config.sprite_types[i], roof_color_override)

	var qt := map.generated_map.sprites_quad_tree
	var renderer := map.get_sprite_renderer()
	var placer := map.generated_map.sprite_placer

	var added_placements := placer.fill_circle(effective_config, location, radius)
	# If couldn't place enough sprites (probably mountains), force place something.
	if added_placements.size() < min_sprites:
		var smallest: MapSpriteType = null
		for candidate in effective_config.sprite_types:
			if not smallest or minf(candidate.default_scale, candidate.min_scale) < minf(smallest.default_scale, smallest.min_scale):
				smallest = candidate
		assert(smallest)
		var sdf := PackedByteArray()
		for i in range(added_placements.size(), min_sprites):
			var placed := await _threaded_try_place_single(map, smallest, sdf, location, radius, fallback_removable_sprites)
			if placed:
				added_placements.append(placed)
			else:
				break

	var anim_time := minf(renderer.animation_duration, MAX_ANIM_TIME / added_placements.size())
	for p in added_placements:
		for replaced in placer.get_intersecting_sprites(p.sprite_type, p.location, p.scale):
			if replaced not in added_placements:
				Utils.ensure(replaced.sprite_type.removable or replaced.sprite_type in fallback_removable_sprites)
				qt.remove(replaced)
				renderer.animate_remove_placement(replaced)
		renderer.animate_add_placement(p)
		if animate:
			GlobalAudioSystem.play(AK.EVENTS.UI_GENERIC_SELECT)
			await map.get_tree().create_timer(Utils.anim_duration(anim_time)).timeout

	return true

func _encode_args() -> Dictionary:
	return {
		'location': [location.x, location.y],
		'radius': radius,
		'config': config.resource_path,
		'min_sprites': min_sprites,
		'fallback_removable_sprites': fallback_removable_sprites.map(
			func(x: MapSpriteType) -> String: return x.resource_path),
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
	config = load(encoded['config'] as String)
	min_sprites = encoded['min_sprites']
	fallback_removable_sprites = []
	for removable_path: String in encoded['fallback_removable_sprites']:
		fallback_removable_sprites.append(load(removable_path))
	var encoded_roof_color: Array = encoded.get('roof_color_override', [0, 0, 0, 0])
	roof_color_override = Color(encoded_roof_color[0] as float,
								encoded_roof_color[1] as float,
								encoded_roof_color[2] as float,
								encoded_roof_color[3] as float)
