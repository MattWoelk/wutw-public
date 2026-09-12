@tool
class_name MapEffect_FloatingStone
extends MapEffect

const FADEIN_TIME : float = 1.0
const FADEOUT_TIME : float = 1.0

@export var float_amplitude_y: float = 8.0
@export var float_amplitude_x: float = 3.0
@export var float_speed: float = 0.8
@export var frame: int = 0

var start_x: float
var start_y: float
var time_offset: float

func _ready() -> void:
	(%Sprite2D as Sprite2D).frame = frame
	time_offset = randf() * 100
	if not Utils.is_in_editor():
		process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta: float) -> void:
	var t := time_offset + Time.get_ticks_msec() / 1000.0
	(%Sprite2D as Sprite2D).position.x = start_x + sin(t * float_speed * 0.7) * float_amplitude_x
	(%Sprite2D as Sprite2D).position.y = start_y + (0.66 * sin(t * float_speed) + 0.33 * sin(t * float_speed + 0.5)) * float_amplitude_y

func start(_map: Map) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 1, FADEIN_TIME)
	tween.play()

func animate_destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, FADEOUT_TIME)
	tween.play()
	await tween.finished
	queue_free()
