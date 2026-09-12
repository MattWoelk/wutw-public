class_name SettlerQuestChallenge_CardAfterForay
extends SettlerQuestChallenge

@export var card_type: CardType

func start_listening(run: Run) -> void:
	run.signals.foray_finished.connect(_on_foray_finished)

func stop_listening(run: Run) -> void:
	run.signals.foray_finished.disconnect(_on_foray_finished)

func _on_foray_finished(_settlement_state: SettlementState) -> void:
	var run := Utils.get_active_run()
	run.signals.settler_quest_challenge_triggered.emit(self)
	run.add_card_to_deck(card_type)

func describe() -> String:
	return tr('Add a %s <term_lower:glyph> to your <term_lower:card_deck> at the end of every <term_lower:foray>.') % card_type.get_term_tag()
