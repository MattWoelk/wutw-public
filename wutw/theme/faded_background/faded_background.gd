class_name FadedBackground
extends Control

signal clicked

@export var autostart: bool = true
@export var default_duration: float = 0.5
@export var starting_fade: float = 1.0

var _tween: Tween

func _ready() -> void:
	(%ColorRect as ColorRect).material = (%ColorRect as ColorRect).material.duplicate()
	var shader_material := (%ColorRect as ColorRect).material as ShaderMaterial
	if autostart:
		fade_in()
	else:
		shader_material.set_shader_parameter('fade', starting_fade)

func fade_in(duration: float = default_duration) -> void:
	GlobalAudioSystem.notify_menu_opened(self)
	await _fade_to(0, 1, duration)

func fade_out(duration: float = default_duration) -> void:
	GlobalAudioSystem.notify_menu_closed(self)
	await _fade_to(1, 0, duration)

func _fade_to(source: float, target: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var shader_material := (%ColorRect as ColorRect).material as ShaderMaterial
	shader_material.set_shader_parameter('fade', source)
	_tween.tween_method(func(value: float) -> void:
		shader_material.set_shader_parameter('fade', value)
	, source, target, duration)
	_tween.play()
	await _tween.finished

func _on_color_rect_gui_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if not mouse_event:
		return
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_MASK_LEFT:
		return
	clicked.emit()
