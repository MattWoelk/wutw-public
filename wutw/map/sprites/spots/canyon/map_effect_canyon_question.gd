@tool
class_name MapEffect_CanyonQuestion
extends MapEffect

@export var max_initial_delay: float = 3.5
@export var fadein_duration: float = 1.5
@export var hold_duration: float = 3.0
@export var fadeout_duration: float = 1.5
@export var end_delay: float = 2.0
@export var hframes: int = 3
@export var vframes: int = 3

var _shader_material: ShaderMaterial

func _ready() -> void:
	_shader_material = (%TextureRect as TextureRect).material.duplicate() as ShaderMaterial
	(%TextureRect as TextureRect).material = _shader_material
	_shader_material.set_shader_parameter('frames_x', hframes)
	_shader_material.set_shader_parameter('frames_y', vframes)

func start(_map: Map) -> void:
	_set_progress(0)
	await get_tree().create_timer(max_initial_delay * randf()).timeout

	var tween := create_tween()
	tween.set_loops()
	tween.tween_callback(func() -> void:
		_shader_material.set_shader_parameter('frame', randi_range(0, hframes * vframes - 1))
	)
	tween.tween_method(_set_progress, 0.0, 1.0, fadein_duration)
	tween.tween_interval(hold_duration)
	tween.tween_method(_set_progress, 1.0, 2.0, fadeout_duration)
	tween.tween_interval(end_delay)
	tween.play()

func animate_destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, 0.5)
	tween.play()
	await tween.finished
	queue_free()

func _set_progress(value: float) -> void:
	_shader_material.set_shader_parameter('t', value)
