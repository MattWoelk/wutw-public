@tool
class_name EventOutcome_AddCard
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/add_card/event_outcome_widget_add_card.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var card_type: CardType

func apply(_event: Event) -> EventOutcomeWidget:
	assert(card_type)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_AddCard
	widget.card_type = card_type
	return widget

func describe(_run: Run) -> String:
	return tr('Get a %s <term_lower:glyph>') % card_type.get_term_tag()
