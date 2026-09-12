class_name SettlerQuestGoal_NumSurveyEpisodes
extends SettlerQuestGoal

@export var num_required: int = 5

func start_listening(run: Run) -> void:
	# Ideally on episode end, but easier to count on survey end.
	run.signals.survey_finished.connect(_on_survey_finished)

func stop_listening(run: Run) -> void:
	run.signals.survey_finished.disconnect(_on_survey_finished)

func _on_survey_finished() -> void:
	var num_finished := 0
	for episodes_list: Array in Utils.get_active_run().get_run_data().finished_episodes.values():
		num_finished += episodes_list.size()
	if num_finished >= num_required:
		achieved.emit()

func describe() -> String:
	assert(num_required > 0)
	return tr('Finish at least %d <term_lower:survey> <term_lower:encounter>s.') % num_required
