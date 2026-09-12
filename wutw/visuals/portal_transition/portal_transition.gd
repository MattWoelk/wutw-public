class_name PortalTransition
extends ColorRect

func _ready() -> void:
	var viewport_image := get_viewport().get_texture().get_image()
	(%SavedTex as TextureRect).texture = ImageTexture.create_from_image(viewport_image)

	var tween := create_tween()
	tween.tween_method(_update_progress, 0.0, .5, 0.7)
	tween.tween_callback(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)
	tween.tween_callback((%SavedTex as TextureRect).hide)
	tween.tween_method(_update_progress, 0.5, 1.0, 1.5)
	tween.tween_callback(queue_free)
	tween.play()

	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_SWIRL)

func _update_progress(p: float) -> void:
	(material as ShaderMaterial).set_shader_parameter('progress', p)
