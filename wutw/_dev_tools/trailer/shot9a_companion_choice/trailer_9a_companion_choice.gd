extends Node2D

func _ready() -> void:
	(%Icon_Spider as Control).modulate = Color(1.35, 1.35, 1.35, 1.0)

	var tooltip := Tooltip.create((%Icon_Spider as Control), _make_tooltip_text(),
		[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.BELOW],
		[Tooltip.Alignment.CENTERED])
	tooltip.show_tooltip()

	await get_tree().create_timer(4.0).timeout

	var unhighlight_tween := create_tween()
	unhighlight_tween.set_ease(Tween.EaseType.EASE_OUT)
	unhighlight_tween.set_trans(Tween.TRANS_CUBIC)
	unhighlight_tween.tween_property(%Icon_Spider, 'modulate', Color(1.0, 1.0, 1.0, 1.0), 1.0)
	unhighlight_tween.play()

	tooltip.hide_tooltip()

	var highlight_tween := create_tween()
	highlight_tween.set_ease(Tween.EaseType.EASE_OUT)
	highlight_tween.set_trans(Tween.TRANS_CUBIC)
	highlight_tween.tween_property(%Icon_Cat, 'modulate', Color(1.35, 1.35, 1.35, 1.0), 1.0)
	highlight_tween.play()

	await highlight_tween.finished
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()

func _make_tooltip_text() -> String:
	var companion_resource := load('res://companions/spider/companion_spider.tres') as Companion
	return ('<header_font_size>[b]%s <term:companion> Ability[/b][/font_size]\n%s' %
			[companion_resource.companion_name, companion_resource.ability_description])
