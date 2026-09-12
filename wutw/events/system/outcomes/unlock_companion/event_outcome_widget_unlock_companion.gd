class_name EventOutcomeWidget_UnlockCompanion
extends EventOutcomeWidget

var companion: Companion

func _ready() -> void:
	assert(companion)
	GlobalSaveGame.unlock_companion(companion)

	(%NameLabel as Label).text = tr(companion.companion_name)
	(%Image as TextureRect).texture = companion.image

	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT],
			[Tooltip.Alignment.BEGIN])

	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.4))
	tween.play()
	await tween.finished

	finished.emit()

func _make_tooltip_text() -> String:
	return (tr('<related_term:companion><header_font_size>[b]%s[/b][/font_size]\n\n%s\n\n<header_font_size>[b]Ability[/b][/font_size]: %s') %
			[companion.get_term_name(true), companion.get_markedup_description(), tr(companion.ability_description)])
