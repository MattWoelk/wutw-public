class_name InkblotTransition
extends TextureRect

func _ready() -> void:
	#await RenderingServer.frame_post_draw
	var viewport_image := get_viewport().get_texture().get_image()
	(material as ShaderMaterial).set_shader_parameter(
		'cleared_texture', ImageTexture.create_from_image(viewport_image))

	var tween := create_tween()
	tween.tween_method(_update_progress, 0.0, 1.0, 0.7)
	tween.tween_callback(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)
	tween.tween_method(_update_progress, 1.0, 2.0, 1.5)
	tween.tween_callback(queue_free)
	tween.play()

	GlobalAudioSystem.play(AK.EVENTS.SFX_TRANSITION_MISC)

func _update_progress(p: float) -> void:
	(material as ShaderMaterial).set_shader_parameter('progress', p)
