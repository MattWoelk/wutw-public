class_name SettlerQuestChallenge_NoHealDuringDurvey
extends SettlerQuestChallenge

func start_listening(run: Run) -> void:
	run.signals.survey_started.connect(_on_survey_started)

func stop_listening(run: Run) -> void:
	run.signals.survey_started.disconnect(_on_survey_started)

func _on_survey_started() -> void:
	Utils.get_active_run().get_current_stage().add_modifier(
		RunVars.Var.INSPIRATION_GAIN_PERCENT, -9999)

func describe() -> String:
	return tr('Cannot restore <term:inspiration> during <term_lower:survey>s.')
