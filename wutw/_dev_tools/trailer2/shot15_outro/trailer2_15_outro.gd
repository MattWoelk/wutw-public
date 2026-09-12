extends Node2D

func _ready() -> void:
	await get_tree().create_timer(3.0).timeout

	var tween := create_tween()
	tween.tween_property(%Logo, 'modulate:a', 1.0, 1)
	tween.play()
	await tween.finished

	await get_tree().create_timer(1.2).timeout

	tween = create_tween()
	tween.tween_property(%CTA, 'modulate:a', 1.0, 1)
	tween.play()
	await tween.finished

	await get_tree().create_timer(1.0).timeout

	(%CatAnimationPlayer as AnimationPlayer).play('react')
	GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_CAT)

	await get_tree().create_timer(7.5).timeout

	if OS.has_feature('movie'):
		get_tree().quit()
