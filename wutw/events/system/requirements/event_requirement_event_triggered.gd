@tool
class_name EventRequirement_EventTriggered
extends EventRequirement

@export var triggered_event: Event
@export var min_stages_since: int = 1
@export var allow_previous_run: bool = false

func is_satisfied(run: Run, _event: Event) -> bool:
	if allow_previous_run:
		return GlobalSaveGame.get_events_state().get_bool_or_default(
			triggered_event.event_id, Event.TRIGGERED_EVER_VAR, false)
	var triggered_stage_index := run.get_events_state().get_int_or_default(
			triggered_event.event_id, Event.TRIGGERED_STAGE_INDEX_VAR, -1)
	if triggered_stage_index == -1:
		return false
	var current_stage_index := run.get_current_stage_index()
	return current_stage_index - triggered_stage_index >= min_stages_since

func to_expression() -> String:
	return 'triggered(' + triggered_event.event_id + ')'

func describe(_run: Run, detailed: bool) -> String:
	if allow_previous_run:
		return (tr('Event ever encountered: ') if detailed else tr('Ever seen ')) + tr(triggered_event.event_name)
	else:
		return (tr('Event encountered: ') if detailed else tr('Seen ')) + tr(triggered_event.event_name)
