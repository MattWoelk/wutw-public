class_name NameScrollDisplay
extends Node2D

signal closed

var _closing := false

func _ready() -> void:
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 1.0, 0.8)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()

func _handle_esc() -> bool:
	_close()
	return true

func _close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(%Main as Control, false)
		(%BG as FadedBackground).fade_out()
		var tween := create_tween()
		tween.tween_property(self, 'modulate:a', 0, 0.8)
		tween.set_speed_scale(Utils.anim_speed())
		tween.play()
		await tween.finished
		closed.emit()
		queue_free()

func _on_close_button_pressed() -> void:
	_close()
