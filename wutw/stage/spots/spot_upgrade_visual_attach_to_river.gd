class_name SpotUpgradeVisual_AttachToRiver
extends SpotUpgradeVisual

@export var sprite_type: MapSpriteType
@export var replaced_sprite_type: MapSpriteType
@export var keep_replaced: bool = false
@export var ignored_colliders: Array[MapSpriteType]

func apply(map: Map, pos: Vector2, radius: float, roof_color_override: Color) -> MapModification:
	var mod := MapModification_AttachToRiver.new()
	mod.location = pos
	mod.radius = radius
	mod.sprite_type = sprite_type
	mod.replaced_sprite_type = replaced_sprite_type
	mod.keep_replaced = keep_replaced
	mod.ignored_colliders = ignored_colliders
	mod.roof_color_override = roof_color_override
	@warning_ignore('redundant_await')
	if await mod.apply(map):
		return mod
	else:
		return null
