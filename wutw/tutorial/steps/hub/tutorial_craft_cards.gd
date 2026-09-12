class_name Tutorial_Craft_Cards
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	Utils.get_active_hub().menu_opened.connect(_on_hub_menu_opened)

func stop_listening() -> void:
	Utils.get_active_hub().menu_opened.disconnect(_on_hub_menu_opened)

func get_tutorial_order() -> int:
	return 10

func _on_hub_menu_opened(menu: Node) -> void:
	if menu is Crafting:
		ready_to_trigger.emit()

func trigger() -> void:
	await Utils.get_active_hub().get_tree().create_timer(1.5).timeout  # Let unroll animation finish.

	var crafting := Utils.get_active_hub().get_opened_menu() as Crafting
	var scroller := crafting.get_node('%ScrollContainer') as ScrollContainer

	_outline_controls([scroller])

	var common_cards := scroller.get_node('%CardTierList_Common') as CardTierList
	var tween := crafting.create_tween()
	tween.tween_property(scroller, 'scroll_vertical', common_cards.position.y - 20, 0.6).set_ease(Tween.EASE_OUT)
	tween.play()
	await tween.finished

	for card in common_cards.get_cards():
		if card.card_type not in GlobalSaveGame.get_unlocked_cards():
			var any_missing_strokes := false
			var strokes := Stroke.get_strokes_for_kanji(card.card_type.symbol)
			for stroke in strokes:
				if GlobalSaveGame.get_stroke_count(stroke) < strokes[stroke]:
					any_missing_strokes = true
					break
			if not any_missing_strokes:
				card.is_selected = true
				break
	await Utils.get_active_hub().get_tree().create_timer(0.3).timeout

	var text := tr('''
This list contains all the <term_lower:glyph>s you have encountered during your <term_lower:run>s.
''').strip_edges()
	_show_tooltip(scroller, text, [Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'craft_cards'
