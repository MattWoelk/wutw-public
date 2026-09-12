class_name EventOutcomeWidget_ChooseRemoveCard
extends EventOutcomeWidget

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func _ready() -> void:
	(%Label as Label).visible = false
	(%Card as Control).visible = false
	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.5))
	tween.play()
	await tween.finished

func _on_button_pressed() -> void:
	var run := Utils.get_active_run()
	var remove_selector := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	remove_selector.cards = run.get_deck_cards().duplicate()
	remove_selector.cards.sort_custom(func(a: CardType, b: CardType) -> bool:
		return CardType.compare(a, b, true)
	)
	remove_selector.title = tr('Choose Glyph to Remove')
	remove_selector.close_button_label = tr('Cancel')
	remove_selector.allow_card_selection = true
	remove_selector.allow_quick_dismiss = false
	remove_selector.card_selected.connect(func(card: Card) -> void:
		run.remove_card_from_deck(card.card_type)
		# Also remove from the current deck being played.
		var stage := run.get_current_stage()
		if stage:
			var deck := stage.get_card_deck()
			deck.erase_card(card.card_type)

		(%Button as Button).visible = false
		(%Label as Label).visible = true

		(%Card as Card).card_type = card.card_type
		(%Card as Card).visible = true

		await remove_selector.close()

		await (%Card as Card).tear_up()

		finished.emit()
	)
	remove_selector.canceled.connect(func() -> void:
		remove_selector.close()
		custom_minimum_size.y = 0
		(%Button as Button).visible = false
		(%Label as Label).visible = true
		(%Label as Label).text = tr('Chose not to remove any glyphs.')
		(%Label as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		finished.emit()
	)
	GlobalUI.add_layer_content(remove_selector, UI.Layer.GAME_MENU_SUBMENU)

func _on_card_selected() -> void:
	(%Card as Card).is_selected = false
