class_name SettlerQuestChallenge_CardOnRedraw
extends SettlerQuestChallenge

@export var card_type: CardType

func start_listening(run: Run) -> void:
	run.signals.redraw_finished.connect(_on_redraw_finished)

func stop_listening(run: Run) -> void:
	run.signals.redraw_finished.disconnect(_on_redraw_finished)

func _on_redraw_finished(_is_first: bool) -> void:
	var run := Utils.get_active_run()
	run.run_or_queue_action(func() -> void:
		run.signals.settler_quest_challenge_triggered.emit(self)
		await run.get_current_stage().get_card_deck().add_card_to_hand(
			card_type, CardDeck.CardDrawReason.SETTLER_QUEST)
	)

func describe() -> String:
	return tr('Add a %s <term_lower:glyph> to your <term_lower:hand> whenever a new <term_lower:hand> is <term_lower:draw>n.') % card_type.get_term_tag()
