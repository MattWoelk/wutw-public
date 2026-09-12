@tool
class_name MapEffect_VanishingCity
extends MapEffect

const FADEIN_TIME : float = 0.5
const FADEOUT_TIME : float = 0.5

func start(_map: Map) -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 1.0, FADEIN_TIME)
	tween.play()
	await tween.finished

func animate_destroy() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, FADEOUT_TIME)
	tween.play()
	await tween.finished
	queue_free()
