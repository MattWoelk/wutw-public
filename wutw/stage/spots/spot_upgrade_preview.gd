@tool
class_name SpotUpgradePreview
extends Control

const MAX_SCALE := 25.0

@export var forced_size: Vector2 = Vector2(200, 140):
	set(value):
		forced_size = value
		if is_node_ready():
			_update()
@export var spot_upgrade: SpotUpgrade:
	set(value):
		if spot_upgrade == value:
			return
		spot_upgrade = value
		if is_node_ready():
			_update()
@export var allow_placeholder: bool = true:
	set(value):
		allow_placeholder = value
		if is_node_ready():
			_update()
@export var inset_factor: float = 0.9:
	set(value):
		inset_factor = value
		if is_node_ready():
			_update()
@export var override_sprite: MapSpriteType:
	set(value):
		if override_sprite == value:
			return
		override_sprite = value
		if is_node_ready():
			_update()
@export var force_instant := false

var _cur_placement: MapSpritePlacement

func _ready() -> void:
	_update()

func _update() -> void:
	var sprite_renderer := (%MapSpriteRenderer as MapSpriteRenderer)

	custom_minimum_size = forced_size
	sprite_renderer.position = forced_size / 2.0

	if _cur_placement:
		if force_instant:
			sprite_renderer.remove_placement(_cur_placement)
		else:
			sprite_renderer.animate_remove_placement(_cur_placement)

	var sprite_type := get_upgrade_sprite()
	if sprite_type:
		var map_rect := _get_sprite_rect(sprite_type)
		var exact_scale := size / map_rect.size
		var uniform_scale := minf(MAX_SCALE, minf(exact_scale.x, exact_scale.y))
		var animate := _cur_placement != null
		_cur_placement = MapSpritePlacement.new()
		_cur_placement.location = -map_rect.get_center() * uniform_scale
		_cur_placement.scale = uniform_scale
		_cur_placement.scale *= inset_factor
		_cur_placement.sprite_type = sprite_type
		if animate and not force_instant:
			sprite_renderer.animate_add_placement(_cur_placement)
		else:
			sprite_renderer.add_placement(_cur_placement)
		(%PlaceholderIcon as TextureRect).visible = false
	else:
		(%PlaceholderIcon as TextureRect).visible = allow_placeholder
		_cur_placement = null

func get_upgrade_sprite() -> MapSpriteType:
	if override_sprite:
		return override_sprite
	for visual in spot_upgrade.visuals if spot_upgrade else []:
		if visual is SpotUpgradeVisual_Add:
			return (visual as SpotUpgradeVisual_Add).sprite_type
		elif visual is SpotUpgradeVisual_Replace:
			return (visual as SpotUpgradeVisual_Replace).new_sprite_type
		elif visual is SpotUpgradeVisual_Upgrade:
			return (visual as SpotUpgradeVisual_Upgrade).new_sprite_type
		elif visual is SpotUpgradeVisual_AttachToRiver:
			return (visual as SpotUpgradeVisual_AttachToRiver).sprite_type
	return null

func _get_sprite_rect(sprite_type: MapSpriteType, sprite_scale: float = 1.0) -> Rect2:
	if sprite_type is MapSpriteType_Composite:
		var components := (sprite_type as MapSpriteType_Composite).components
		var map_rect: Rect2
		for component in components:
			var component_rect := _get_sprite_rect(component.sprite_type, component.scale * component.sprite_type.default_scale)
			component_rect.position += component.offset
			if map_rect:
				map_rect = map_rect.merge(component_rect)
			else:
				map_rect = component_rect
		return map_rect
	else:
		var map_rect := _get_map_rect(sprite_type)
		var top_left := map_rect.position * sprite_scale - map_rect.size * sprite_scale / 2
		return Rect2(top_left, map_rect.size * sprite_scale)

func _get_map_rect(sprite_type: MapSpriteType) -> Rect2:
	var pos := sprite_type.map_rect.position
	var rect_size := sprite_type.map_rect.size
	if rect_size.x < 0:
		pos.x += rect_size.x
		rect_size.x *= -1
	if rect_size.y < 0:
		pos.y += rect_size.y
		rect_size.y *= -1
	return Rect2(pos, rect_size)
