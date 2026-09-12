class_name SettlerQuestChallenge_DamagePerStage
extends SettlerQuestChallenge

@export var damage: int = 3

func start_listening(run: Run) -> void:
	run.signals.stage_started.connect(_on_stage_started)

func stop_listening(run: Run) -> void:
	run.signals.stage_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	var run := Utils.get_active_run()
	run.run_or_queue_action(func() -> void:
		run.signals.settler_quest_challenge_triggered.emit(self)
		run.modify_inspiration(-damage, Run.InspirationChangeReason.SETTLER_QUEST)
	)

func describe() -> String:
	return tr('Lose %d <term_lower:inspiration> at the start of every <term_lower:stage>.') % damage
