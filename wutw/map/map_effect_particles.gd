@tool
class_name MapEffect_Particles
extends MapEffect

const FADEIN_TIME : float = 1.0
const FADEOUT_TIME : float = 1.0

func start(_map: Map) -> void:
	for child in get_children():
		if child is GPUParticles2D:
			(child as GPUParticles2D).emitting = true

	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 1, FADEIN_TIME)
	tween.play()

func animate_destroy() -> void:
	for child in get_children():
		if child is GPUParticles2D:
			(child as GPUParticles2D).emitting = false
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0, FADEOUT_TIME)
	tween.play()
	await tween.finished
	queue_free()
