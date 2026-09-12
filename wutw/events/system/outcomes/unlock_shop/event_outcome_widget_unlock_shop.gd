class_name EventOutcomeWidget_UnlockShop
extends EventOutcomeWidget

var shop_type: ShopType

func _ready() -> void:
	var run := Utils.get_active_run()
	assert(shop_type)
	var settlement := run.get_current_settlement()
	assert(settlement)
	settlement.add_shop(shop_type)

	(%NameLabel as Label).text = tr(shop_type.title)
	(%Image as TextureRect).texture = shop_type.background_texture as Texture2D

	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.LEFT], [Tooltip.Alignment.BEGIN])

	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.4))
	tween.play()
	await tween.finished

	finished.emit()

func _make_tooltip_text() -> String:
	return (tr('<related_term:relic><header_font_size>[b]%s[/b][/font_size]\n\n%s') %
			[shop_type.get_term_name(true), shop_type.get_markedup_description()])
