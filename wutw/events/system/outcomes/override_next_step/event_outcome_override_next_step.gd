@tool
class_name EventOutcome_OverrideNextStep
extends EventOutcome

@export var next_step_id: String
@export_multiline var result_text: String
@export var description: String = '<unset>'

func apply(_event: Event) -> EventOutcomeWidget:
	var run := Utils.get_active_run()
	var event_scene := run.get_current_event_scene()
	if event_scene:
		event_scene.get_current_step_scene().override_next_step(next_step_id, tr(result_text))
	else:
		Utils.ensure(not next_step_id)
		var stage := run.get_current_stage()
		assert(stage)
		var survey := stage.get_survey()
		assert(survey)
		survey.override_result_text(tr(result_text))
	return null

func describe(_run: Run) -> String:
	if description != '<unset>':
		return tr(description)
	else:
		push_warning('Event choice outcome overrides next step; should use a custom description.')
		return ''
