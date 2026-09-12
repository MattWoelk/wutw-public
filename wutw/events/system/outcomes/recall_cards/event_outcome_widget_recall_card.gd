class_name EventOutcomeWidget_RecallCard
extends EventOutcomeWidget

static var DECK_VIEWER_SCENE := AsyncLoadedResource.new('res://cards/viewer/card_deck_viewer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

var ui_layer: UI.Layer = UI.Layer.GAME_MENU_SUBMENU

var _card_selector: CardDeckViewer

func _ready() -> void:
	(%Label as Label).visible = false
	(%Card as Card).visible = false
	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, Utils.anim_duration(0.5))
	tween.play()
	await tween.finished

func _on_button_pressed() -> void:
	_card_selector = DECK_VIEWER_SCENE.instantiate_loaded_scene() as CardDeckViewer
	var recallable_cards := GlobalSaveGame.get_unlocked_cards()
	var run := Utils.get_active_run()
	for card in run.get_deck_cards():
		recallable_cards.erase(card)
	if not recallable_cards:
		# Somehow, we already have all the cards we could recall. Allow copies.
		recallable_cards = GlobalSaveGame.get_unlocked_cards()
	_card_selector.cards = recallable_cards
	_card_selector.cards.sort_custom(CardType.compare)
	_card_selector.title = tr('Choose Glyph to Recall')
	_card_selector.close_button_label = tr('Cancel')
	_card_selector.allow_card_selection = true
	_card_selector.allow_quick_dismiss = false
	_card_selector.card_selected.connect(_on_card_selected.bind(run))
	_card_selector.canceled.connect(_on_card_selected.bind(null, run))
	GlobalUI.add_layer_content(_card_selector, ui_layer)

func _on_card_selected(card: Card, run: Run) -> void:
	(%Button as Button).visible = false
	if card:
		run.add_card_to_deck(card.card_type)
		var stage := run.get_current_stage()
		if stage:
			stage.get_card_deck().add_card_to_hand(card.card_type, CardDeck.CardDrawReason.EVENT)
		_card_selector.close()
		(%Card as Card).card_type = card.card_type
		(%Card as Card).visible = true
		finished.emit()
	else:
		(%Label as Label).text = tr('Chose not to recall a glyph.')
		finished.emit()
	_card_selector = null
	(%Label as Label).visible = true
