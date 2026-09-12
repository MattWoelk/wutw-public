@tool
class_name Tai_Hub
extends HubCompanion

@export var distance: float = -200.0
@export var duration: float = 40.0
@export var wave_amplitude: float = 2.5
@export var wave_interval: float = 0.08
@export var fade_duration: float = 0.5
@export var max_wait: float = 10.0

var _start_position: Vector2
var _current_time: float

@warning_ignore('unused_private_class_variable')
@export_tool_button('Start')
var _start_tool := _start

@warning_ignore('unused_private_class_variable')
@export_tool_button('Stop')
var _start_stop := _stop

func _ready() -> void:
	set_process(false)
	if not Utils.is_in_editor():
		super._ready()
		_start()

func _process(delta: float) -> void:
	if _current_time >= 1.0:
		_stop()
		_start()
		return

	_current_time += delta / duration
	var x_offset := _current_time * distance
	var y_offset := wave_amplitude * _noisy_wave(_current_time / wave_interval)
	position = _start_position + Vector2(x_offset, y_offset)

	var threshold := fade_duration / duration
	var depth := 1.0 - clampf(minf(_current_time - threshold, (1.0 - _current_time) - threshold) / threshold, 0.0, 1.0)
	(%Sprite as Sprite2D).set_instance_shader_parameter('depth', depth)

func _start() -> void:
	_start_position = position
	_current_time = 0.0
	(%Sprite as Sprite2D).flip_h = distance > 0
	await get_tree().create_timer(randf() * max_wait).timeout
	set_process(true)

func _stop() -> void:
	position = _start_position
	set_process(false)
	if Utils.is_in_editor():
		(%Sprite as Sprite2D).set_instance_shader_parameter('depth', 0.0)

func _noisy_wave(t: float) -> float:
	var y := 1.0 * sin(1.0 * t)
	y += 0.5 * sin(2.7 * t + 1.2)
	y += 0.25 * sin(5.3 * t + 4.5)
	y += 0.125 * sin(11.1 * t + 0.8)
	return y
