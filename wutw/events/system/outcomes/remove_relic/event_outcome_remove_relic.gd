@tool
class_name EventOutcome_RemoveRelic
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/remove_relic/event_outcome_widget_remove_relic.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var is_random: bool = false
@export var relic: Relic

func apply(_event: Event) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_RemoveRelic
	widget.is_random = is_random
	widget.relic = relic
	return widget

func describe(_run: Run) -> String:
	if is_random:
		return tr('Lose a random <term_lower:relic>')
	else:
		return tr('Lose <term_lower:relic>: %s') % relic.get_term_tag()
