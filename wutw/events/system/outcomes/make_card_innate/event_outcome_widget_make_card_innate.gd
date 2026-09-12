class_name EventOutcomeWidget_MakeCardInnate
extends EventOutcomeWidget

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var ui_layer: UI.Layer = UI.Layer.GAME_MENU_SUBMENU

func _ready() -> void:
	(%Label as Label).visible = false
	(%Card as Card).visible = false
	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.5))
	tween.play()
	await tween.finished

func _on_button_pressed() -> void:
	var run := Utils.get_active_run()
	var card_selector := DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	var cards := run.get_deck_cards().duplicate()
	for card in run.get_innate_cards():
		cards.erase(card)
	card_selector.cards = cards
	card_selector.cards.sort_custom(CardType.compare)
	card_selector.title = tr('Choose Glyph to Make Innate')
	card_selector.close_button_label = tr('Cancel')
	card_selector.allow_card_selection = true
	card_selector.allow_quick_dismiss = false
	card_selector.card_selected.connect(func(card: Card) -> void:
		(%Button as Button).visible = false
		(%Label as Label).visible = true
		(%Card as Card).card_type = card.card_type
		(%Card as Card).visible = true
		run.make_card_innate(card.card_type)
		card_selector.close()
		finished.emit()
	)
	card_selector.canceled.connect(func() -> void:
		(%Button as Button).visible = false
		(%Label as Label).visible = true
		(%Label as Label).text = tr('Chose not to make any glyph innate.')
		card_selector.close()
		finished.emit()
	)
	GlobalUI.add_layer_content(card_selector, ui_layer)
