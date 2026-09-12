class_name ZoomTransition
extends TextureRect

func _ready() -> void:
	texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())

	var tween := create_tween()
	tween.tween_property(self, 'scale', Vector2(1.096, 1.119), 1.5)  # Ratio of cuscene content to FHD.
	tween.tween_callback(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)
	tween.tween_property(self, 'modulate:a', 0.0, 1.0)
	tween.tween_callback(queue_free)
	tween.play()
