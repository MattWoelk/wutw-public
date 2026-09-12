@tool
class_name MapEffectsSystem
extends Node2D

@export var map: Map:
	set(value):
		if map == value:
			return
		if map:
			_clear_map()
		map = value
		if map:
			_setup_map()
@export var debug_renderer: MapSpriteRenderer

@export_tool_button('Regenerate') @warning_ignore('unused_private_class_variable')
var _regenerate_tool := regenerate

var _effects: Dictionary[MapSpritePlacement, Array]  #Array[MapEffect]

func _ready() -> void:
	Utils.clear_node(self)
	if debug_renderer and not map:
		_setup_map()

func regenerate() -> void:
	_clear_map()
	_setup_map()

func _setup_map() -> void:
	for placement in _get_renderer().placements:
		_on_sprite_added(placement)
	_get_renderer().placement_added.connect(_on_sprite_added)
	_get_renderer().placement_removed.connect(_on_sprite_removed)

func _clear_map() -> void:
	Utils.clear_node(self)
	_effects.clear()
	_get_renderer().placement_added.disconnect(_on_sprite_added)
	_get_renderer().placement_removed.disconnect(_on_sprite_removed)

func _on_sprite_added(placement: MapSpritePlacement) -> void:
	if not GameSettings.Display.enable_map_effects.value():
		return
	assert(placement not in _effects)
	_effects[placement] = []
	for effect_attachment in placement.sprite_type.get_effects_recursive():
		var effect_instance := effect_attachment.scene.instantiate() as MapEffect
		add_child(effect_instance)
		effect_instance.owner = owner
		effect_instance.position = placement.location + effect_attachment.offset * placement.scale
		effect_instance.scale = Vector2.ONE * placement.scale * effect_attachment.scale
		effect_instance.start(map)
		_effects[placement].append(effect_instance)

func _on_sprite_removed(placement: MapSpritePlacement) -> void:
	if not GameSettings.Display.enable_map_effects.value():
		return
	if placement in _effects:
		for effect_instance: MapEffect in _effects[placement]:
			effect_instance.animate_destroy()
	_effects.erase(placement)

func _get_renderer() -> MapSpriteRenderer:
	if debug_renderer:
		return debug_renderer
	else:
		return map.get_sprite_renderer()
