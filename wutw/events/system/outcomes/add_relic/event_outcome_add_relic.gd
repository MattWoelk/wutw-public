@tool
class_name EventOutcome_AddRelic
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/add_relic/event_outcome_widget_add_relic.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var relic: Relic

func apply(_event: Event) -> EventOutcomeWidget:
	assert(relic)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_AddRelic
	widget.relic = relic
	return widget

func describe(_run: Run) -> String:
	return tr('Get <term_lower:relic>: %s') % relic.get_term_tag()
