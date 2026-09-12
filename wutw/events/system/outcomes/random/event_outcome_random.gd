@tool
class_name EventOutcome_Random
extends EventOutcome

@export var suboutcomes: Dictionary[EventOutcome, float]
@export var description: String = '<unset>'

func apply(event: Event) -> EventOutcomeWidget:
	assert(not suboutcomes.is_empty())
	var outcome := Utils.get_active_run().get_events_random().pick_weighted_dict(suboutcomes)[0] as EventOutcome
	if outcome:
		return outcome.apply(event)
	else:
		return null

func describe(_run: Run) -> String:
	if description != '<unset>':
		return tr(description)
	else:
		push_warning('Event choice outcome has random element; should use a custom description.')
		return tr('Multiple possible outcomes.')
