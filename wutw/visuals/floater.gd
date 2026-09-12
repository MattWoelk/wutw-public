class_name Floater
extends Sprite2D

@export var float_amplitude_y: float = 8.0
@export var float_amplitude_x: float = 3.0
@export var float_speed: float = 0.8

var start_x: float
var start_y: float
var time_offset: float

func _ready() -> void:
	start_x = offset.x
	start_y = offset.y
	time_offset = randf() * 100

func _process(delta: float) -> void:
	time_offset += delta
	offset.x = start_x + sin(time_offset * float_speed * 0.7) * float_amplitude_x
	offset.y = start_y + (0.66 * sin(time_offset * float_speed) + 0.33 * sin(time_offset * float_speed + 0.5)) * float_amplitude_y
