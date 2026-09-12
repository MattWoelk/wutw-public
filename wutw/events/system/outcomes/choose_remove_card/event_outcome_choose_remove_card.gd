@tool
class_name EventOutcome_ChooseRemoveCard
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/choose_remove_card/event_outcome_widget_choose_remove_card.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func apply(_event: Event) -> EventOutcomeWidget:
	return WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_ChooseRemoveCard

func describe(_run: Run) -> String:
	return tr('<term:remove_card> a chosen <term_lower:glyph>')
