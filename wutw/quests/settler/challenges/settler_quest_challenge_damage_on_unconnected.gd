class_name SettlerQuestChallenge_DamageOnUnconnected
extends SettlerQuestChallenge

@export var damage: int = 5

func start_listening(run: Run) -> void:
	run.signals.harmonization_finished.connect(_on_harmonization_finished)

func stop_listening(run: Run) -> void:
	run.signals.harmonization_finished.disconnect(_on_harmonization_finished)

func _on_harmonization_finished() -> void:
	var run := Utils.get_active_run()
	var unconnected := 0
	for settlement in run.get_settlements():
		if not settlement.is_settlement_connected():
			unconnected += 1
	run.signals.settler_quest_challenge_triggered.emit(self)
	run.modify_inspiration(-damage * unconnected, Run.InspirationChangeReason.SETTLER_QUEST)

func describe() -> String:
	return tr('Lose %d <term:inspiration> for each un<term_lower:connect_settlement>ed <term_lower:settlement> at the end of a <term_lower:harmonization>.') % damage
