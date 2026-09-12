class_name SpotUpgradeVisual_Replace
extends SpotUpgradeVisual

@export var old_sprite_types: Array[MapSpriteType]
@export var new_sprite_type: MapSpriteType
@export var offset: Vector2
@export var leave_original: bool
@export var extra_removables: Array[MapSpriteType]

func apply(map: Map, pos: Vector2, radius: float, roof_color_override: Color) -> MapModification:
	var mod := MapModification_Replace.new()
	mod.location = pos
	mod.radius = radius
	mod.offset = offset
	mod.old_sprite_types = old_sprite_types
	mod.new_sprite_type = new_sprite_type
	mod.leave_original = leave_original
	mod.extra_removables = extra_removables
	mod.roof_color_override = roof_color_override
	@warning_ignore('redundant_await')
	if await mod.apply(map):
		return mod
	else:
		return null
