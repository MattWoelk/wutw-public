@tool
class_name EventOutcome_MakeCardInnate
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/make_card_innate/event_outcome_widget_make_card_innate.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func apply(_event: Event) -> EventOutcomeWidget:
	return WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_MakeCardInnate

func describe(_run: Run) -> String:
	return tr('Make a <term:glyph> <term:innate>')
