class_name Tutorial_NegativeCards
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.card_added_to_hand.connect(_on_card_added_to_hand)

func stop_listening() -> void:
	Utils.get_active_run().signals.card_added_to_hand.disconnect(_on_card_added_to_hand)

func _on_card_added_to_hand(card: Card, _reason: CardDeck.CardDrawReason, _from_discards: bool) -> void:
	if card.card_type.rarity == CardType.Rarity.NEGATIVE:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(0.5).timeout  # Let stage UI finish animating.

	# Negative cards are often first encountered in events. Make sure we wait for them to finish.
	while run.get_current_event_scene():
		await run.get_tree().process_frame

	var text := tr('''
You have encountered a <term:negative_glyph>.

Any such <term_lower:glyph>s remaining in your <term_lower:hand> at the end of a <term_lower:turn> are <term_lower:cast_card> automatically.
''').strip_edges()

	var negative_card: Card
	for card in run.get_current_stage().get_card_deck().get_hand_cards():
		if card.card_type.rarity == CardType.Rarity.NEGATIVE:
			negative_card = card
			break
	assert(negative_card)

	_outline_controls([negative_card])
	_show_tooltip(negative_card, text, [Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'negative_cards'
