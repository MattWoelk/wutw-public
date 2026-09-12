@tool
class_name EventOutcome_RemoveCard
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/remove_card/event_outcome_widget_remove_card.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var card_type: CardType
@export var aspect: AspectType = null

func apply(_event: Event) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_RemoveCard
	widget.card_type = card_type
	widget.aspect = aspect
	return widget

func describe(_run: Run) -> String:
	if card_type:
		return tr('Lose the %s <term_lower:glyph>') % card_type.get_term_tag()
	elif aspect:
		return tr('Lose a %s <term_lower:glyph>') % aspect.get_term_tag()
	else:
		return tr('Lose a random <term_lower:glyph>')
