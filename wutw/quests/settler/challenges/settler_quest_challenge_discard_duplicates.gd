class_name SettlerQuestChallenge_DiscardDuplicates
extends SettlerQuestChallenge

func start_listening(run: Run) -> void:
	run.signals.card_added_to_hand.connect(_on_card_added_to_hand)

func stop_listening(run: Run) -> void:
	run.signals.card_added_to_hand.disconnect(_on_card_added_to_hand)

func _on_card_added_to_hand(card: Card, _reason: CardDeck.CardDrawReason, _from_discards: bool) -> void:
	var run := Utils.get_active_run()
	run.run_or_queue_action(func() -> void:
		var deck := run.get_current_stage().get_card_deck()
		if card in deck.get_hand_cards():
			for other in deck.get_hand_cards():
				if card != other and card.card_type == other.card_type:
					run.signals.settler_quest_challenge_triggered.emit(self)
					await deck.discard(card, CardDeck.DiscardReason.SETTLER_QUEST)
					return
	)

func describe() -> String:
	return tr('Any duplicate <term_lower:glyph>s added to your <term_lower:hand> are immediately <term_lower:discard>ed.')
