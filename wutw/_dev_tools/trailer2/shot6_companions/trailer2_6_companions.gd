extends Node2D

func _ready() -> void:
	#(%Fox as CanvasItem).modulate = Color(1.35, 1.35, 1.35, 1.0)
	#(%Fox as CanvasItem).modulate = Color(.9, .9, .9, 1.0)

	(%CraneAnimationPlayer as AnimationPlayer).play('idle', -1, 1.5)
	(%FoxAnimationPlayer as AnimationPlayer).play('idle', -1, 1.5)
	(%SnakeAnimationPlayer as AnimationPlayer).play('idle', -1, 1.5)
	(%TanukiAnimationPlayer as AnimationPlayer).play('idle', -1, 1.5)
	(%SpiderAnimationPlayer as AnimationPlayer).play('idle', -1, 1.5)
	(%FoxAnimationPlayer as AnimationPlayer).play('idle', -1, 1.5)

	await get_tree().create_timer(2.0).timeout

	var tooltip := Tooltip.create((%TooltipAnchor as Control), _make_tooltip_text(),
		[Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.BELOW],
		[Tooltip.Alignment.CENTERED])
	tooltip.show_tooltip()

	#await get_tree().create_timer(4.0).timeout

	GlobalAudioSystem.play(AK.EVENTS.SFX_ANIMAL_COMPANION_FOX)
	(%FoxAnimationPlayer as AnimationPlayer).play('react')
	(%FoxAnimationPlayer as AnimationPlayer).queue('idle')
	var unhighlight_tween := create_tween()
	unhighlight_tween.set_ease(Tween.EaseType.EASE_OUT)
	unhighlight_tween.set_trans(Tween.TRANS_CUBIC)
	#unhighlight_tween.tween_property(%Fox, 'modulate', Color(1.0, 1.0, 1.0, 1.0), 1.0)
	unhighlight_tween.tween_property(%Fox, 'modulate', Color(1.15, 1.15, 1.15, 1.0), 1.0)
	unhighlight_tween.play()

	#tooltip.hide_tooltip()

	#var highlight_tween := create_tween()
	#highlight_tween.set_ease(Tween.EaseType.EASE_OUT)
	#highlight_tween.set_trans(Tween.TRANS_CUBIC)
	#highlight_tween.tween_property(%Icon_Cat, 'modulate', Color(1.35, 1.35, 1.35, 1.0), 1.0)
	#highlight_tween.play()
	#await highlight_tween.finished

	await get_tree().create_timer(4.0).timeout

	if OS.has_feature('movie'):
		get_tree().quit()

func _make_tooltip_text() -> String:
	var companion_resource := load('res://companions/fox/companion_fox.tres') as Companion
	return ('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s' %
			[companion_resource.companion_name, companion_resource.ability_description])
