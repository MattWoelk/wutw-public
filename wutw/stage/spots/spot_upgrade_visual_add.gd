class_name SpotUpgradeVisual_Add
extends SpotUpgradeVisual

@export var sprite_type: MapSpriteType
@export var biome: MapBiomes.Biome
@export var extra_removables: Array[MapSpriteType]
@export var clip_margin: float = 2.0

func apply(map: Map, pos: Vector2, radius: float, roof_color_override: Color) -> MapModification:
	var mod := MapModification_Place.new()
	mod.location = pos
	mod.radius = radius
	mod.biome = biome
	mod.sprite_type = sprite_type
	mod.extra_removables = extra_removables
	mod.clip_margin = clip_margin
	mod.roof_color_override = roof_color_override
	if await mod.apply(map):
		return mod
	else:
		return null
