@abstract
class_name MapModification
extends RefCounted

# Abstract, but if we mark it as such, the static analyzer can't guess it's a coroutine.
# It's more useful to get warnings at call sites than at the implementations, of which there are fewer.
func apply(_map: Map, _animate: bool = true) -> bool:
	Utils.ensure(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	return false
@abstract func _encode_args() -> Dictionary
@abstract func _decode_args(encoded: Dictionary) -> void

func encode() -> Dictionary:
	var type: String
	if self is MapModification_Place:
		type = 'place'
	elif self is MapModification_PlaceManual:
		type = 'place_manual'
	elif self is MapModification_Replace:
		type = 'replace'
	elif self is MapModification_Upgrade:
		type = 'upgrade'
	elif self is MapModification_Fill:
		type = 'fill'
	elif self is MapModification_AttachToRiver:
		type = 'attach_to_river'
	elif self is MapModification_Road:
		type = 'road'
	else:
		Utils.ensure(false)
	return {
		'type': type,
		'args': _encode_args()
	}

static func decode(encoded: Dictionary) -> MapModification:
	var type := encoded['type'] as String
	var result: MapModification
	match type:
		'place': result = MapModification_Place.new()
		'place_manual': result = MapModification_PlaceManual.new()
		'replace': result = MapModification_Replace.new()
		'upgrade': result = MapModification_Upgrade.new()
		'fill': result = MapModification_Fill.new()
		'attach_to_river': result = MapModification_AttachToRiver.new()
		'road': result = MapModification_Road.new()
		_: Utils.ensure(false); return null
	result._decode_args(encoded['args'] as Dictionary)
	return result

func _setup_random(map: Map, location: Vector2) -> void:
	# Ensure randomization is consistent.
	# HACK: We really shouldn't modify global state, but worst case is inconsistent sprite randomization,
	#       which doesn't affect gameplay, and looks no worse.
	map.generated_map.sprite_placer.reseed_random(floori(location.x * 100 + location.y))

func _threaded_try_place_single(
		map: Map, sprite_type: MapSpriteType, biome_sdf: PackedByteArray,
		search_origin: Vector2, max_distance: float, extra_removable: Array[MapSpriteType] = [],
		skip_clip: bool = false, clip_margin: float = 1.0) -> MapSpritePlacement:
	await map.modification_mutex.lock()
	var placer := map.generated_map.sprite_placer
	var thread := Thread.new()
	var result: Array[MapSpritePlacement] = [null]
	thread.start(func() -> void:
		result[0] = placer.try_place_single(sprite_type, biome_sdf,
			search_origin, max_distance, extra_removable, skip_clip, clip_margin)
	)
	while thread.is_alive():
		await map.get_tree().process_frame
	thread.wait_to_finish()
	map.modification_mutex.unlock()
	return result[0]

func _replace_roof_color(sprite_type: MapSpriteType, roof_color_override: Color) -> MapSpriteType:
	if roof_color_override.a < 0.5:
		return sprite_type
	elif sprite_type is MapSpriteType_Building:
		var copy := sprite_type.duplicate() as MapSpriteType_Building
		copy.canonical_path_override = sprite_type.canonical_path_override if sprite_type.canonical_path_override else sprite_type.resource_path
		copy.roof_color = roof_color_override
		return copy
	elif sprite_type is MapSpriteType_Composite:
		var composite := sprite_type.duplicate() as MapSpriteType_Composite
		composite.canonical_path_override = sprite_type.canonical_path_override if sprite_type.canonical_path_override else sprite_type.resource_path
		composite.components = composite.components.duplicate()
		for i in composite.components.size():
			var component := composite.components[i]
			var replaced := _replace_roof_color(component.sprite_type, roof_color_override)
			if replaced != component.sprite_type:
				composite.components[i] = component.duplicate()
				composite.components[i].sprite_type = replaced
		return composite
	else:
		return sprite_type
