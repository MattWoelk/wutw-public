class_name SettlerQuestChallenge_DupeCardPerForay
extends SettlerQuestChallenge

func start_listening(run: Run) -> void:
	run.signals.foray_finished.connect(_on_foray_finished)

func stop_listening(run: Run) -> void:
	run.signals.foray_finished.disconnect(_on_foray_finished)

func _on_foray_finished(_settlement_state: SettlementState) -> void:
	var run := Utils.get_active_run()
	var card_type: CardType = run.get_card_deck_random().pick(run.get_deck_cards())
	run.signals.settler_quest_challenge_triggered.emit(self)
	run.add_card_to_deck(card_type)

func describe() -> String:
	return tr('Duplicate a random <term_lower:glyph> in your <term_lower:card_deck> at the end of every <term_lower:foray>.')
