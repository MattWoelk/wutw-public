class_name MapModification_Place
extends MapModification

var location: Vector2
var radius: float
var biome: MapBiomes.Biome
var sprite_type: MapSpriteType
var force: bool = false
var extra_removables: Array[MapSpriteType]
var clip_margin: float = 2.0
var roof_color_override: Color = Color.TRANSPARENT

func apply(map: Map, _animate: bool = true) -> bool:
	Utils.ensure(not sprite_type.resource_path.is_empty())  # Must be reloadable.
	_setup_random(map, location)

	var effective_sprite_type := _replace_roof_color(sprite_type, roof_color_override)

	var placer := map.generated_map.sprite_placer
	var qt := map.generated_map.sprites_quad_tree
	var sdf := map.generated_map.raw_biome_sdfs[biome] if biome else PackedByteArray()
	var renderer := map.get_sprite_renderer()

	var placed := await _threaded_try_place_single(map, effective_sprite_type, sdf, location, radius, extra_removables, biome == MapBiomes.Biome.SEA, clip_margin)
	if placed:
		for intersecting in placer.get_intersecting_sprites(effective_sprite_type, placed.location):
			if intersecting != placed:
				qt.remove(intersecting)
				renderer.animate_remove_placement(intersecting)
		renderer.animate_add_placement(placed)
		return true
	else:
		if force:  # Couldn't place. E.g. area full of mountains.
			for intersecting in placer.get_intersecting_sprites(effective_sprite_type, location):
				qt.remove(intersecting)
				renderer.animate_remove_placement(intersecting)
			placed = placer.place_single(effective_sprite_type, location)
			renderer.animate_add_placement(placed)
			return true
		else:
			return false

func _encode_args() -> Dictionary:
	return {
		'location': [location.x, location.y],
		'radius': radius,
		'biome': biome as int,
		'sprite_type': sprite_type.resource_path,
		'force': force,
		'extra_removables': extra_removables.map(func(x: MapSpriteType) -> String: return x.resource_path),
		'clip_margin': clip_margin,
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
	sprite_type = load(encoded['sprite_type'] as String)
	force = encoded['force']
	extra_removables = []
	for removable_path: String in encoded['extra_removables']:
		extra_removables.append(load(removable_path))
	clip_margin = encoded.get('clip_margin', 2.0)
	var encoded_roof_color: Array = encoded.get('roof_color_override', [0, 0, 0, 0])
	roof_color_override = Color(encoded_roof_color[0] as float,
								encoded_roof_color[1] as float,
								encoded_roof_color[2] as float,
								encoded_roof_color[3] as float)
