@tool
class_name HubAmbientSound
extends Node2D

@export var sound: WwiseEvent
@export var radius: float = 100.0:
	set(value):
		radius = value
		queue_redraw()
@export var debug_draw: bool = false:
	set(value):
		debug_draw = value
		queue_redraw()

func _draw() -> void:
	if debug_draw:
		draw_circle(Vector2.ZERO, radius, Color.RED, false, 1, true)
