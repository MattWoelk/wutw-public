@tool
class_name Aspect
extends Control

const RADIUS: int = 18

@export var aspect_type: AspectType:
	set(value):
		aspect_type = value
		if is_node_ready():
			_update()

func _ready() -> void:
	_update()
	if not Utils.is_in_editor():
		GlobalContextHighlight.offer_on_hover(ContextHighlight.aspects(self, [aspect_type]))
		# DISABLED: Only important in starter tutorial, which uses custom arrows instead.
		#GlobalContextHighlight.request_changed.connect(func(requested: ContextHighlight.Context) -> void:
		#	if requested and load('res://glossary/terms/standalone/term_aspect.tres') in requested.terms:
		#		scale = Vector2(1.3, 1.3)
		#	else:
		#		scale = Vector2.ONE
		#)
		GlobalGameSettings.changed.connect(_update)

func _get_minimum_size() -> Vector2:
	return Vector2(RADIUS * 2, RADIUS * 2)

func _update() -> void:
	if aspect_type:
		(%IconTexture as TextureRect).texture = aspect_type.get_used_icon()
