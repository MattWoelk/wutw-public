@tool
class_name EventOutcome_ChooseRelic
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/choose_relic/event_outcome_widget_choose_relic.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var relic_choice_pool: Array[Relic]

func apply(_event: Event) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_ChooseRelic
	widget.relic_choice_pool = relic_choice_pool
	return widget

func describe(_run: Run) -> String:
	return tr('Choose from a pool of random <term_lower:relic>s')
