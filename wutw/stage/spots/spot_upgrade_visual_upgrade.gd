class_name SpotUpgradeVisual_Upgrade
extends SpotUpgradeVisual

@export var old_sprite_type: MapSpriteType
@export var new_sprite_type: MapSpriteType
@export var biome: MapBiomes.Biome
@export var extra_removables: Array[MapSpriteType]

func apply(map: Map, pos: Vector2, radius: float, roof_color_override: Color) -> MapModification:
	var mod := MapModification_Upgrade.new()
	mod.location = pos
	mod.radius = radius
	mod.biome = biome
	mod.old_sprite_type = old_sprite_type
	mod.new_sprite_type = new_sprite_type
	mod.extra_removables = extra_removables
	mod.roof_color_override = roof_color_override
	if await mod.apply(map):
		return mod
	else:
		return null
