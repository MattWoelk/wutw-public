class_name EventOutcomeWidget_AddCard
extends EventOutcomeWidget

var card_type: CardType

func _ready() -> void:
	(%Card as Card).card_type = card_type
	(%Card as Card).modulate.a = 0
	(%Card as Card).new_icon_visible = not GlobalSaveGame.has_seen_card(card_type)

	var run := Utils.get_active_run()
	run.add_card_to_deck(card_type)
	var stage := run.get_current_stage()
	if stage:
		stage.get_card_deck().add_card_to_hand(card_type, CardDeck.CardDrawReason.EVENT)

	var tween := create_tween()
	(%Label as Control).modulate.a = 0
	tween.tween_property(%Label, 'modulate:a', 1.0, Utils.anim_duration(0.4))
	tween.play()
	await tween.finished

	await (%Card as Card).animate_appear()

	finished.emit()

func _on_card_selected() -> void:
	(%Card as Card).is_selected = false
