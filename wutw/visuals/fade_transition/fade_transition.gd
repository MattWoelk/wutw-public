class_name FadeTransition
extends ColorRect

func _ready() -> void:
	var viewport_image := get_viewport().get_texture().get_image()
	(%SavedTex as TextureRect).texture = ImageTexture.create_from_image(viewport_image)

	var tween := create_tween()
	tween.tween_property(%SavedTex, 'modulate:a', 0.0, 1.0)
	tween.tween_property(self, 'modulate:a', 0.0, 0.5)
	tween.tween_callback(queue_free)
	tween.play()

	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_MISC)
