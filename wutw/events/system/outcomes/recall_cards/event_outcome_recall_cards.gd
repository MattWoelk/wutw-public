@tool
class_name EventOutcome_RecallCards
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/recall_cards/event_outcome_widget_recall_card.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func apply(_event: Event) -> EventOutcomeWidget:
	return WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_RecallCard

func describe(_run: Run) -> String:
	return tr('Recall an <term:craft>d <term:glyph> to <term_lower:add_card> to your <term:card_deck>')
