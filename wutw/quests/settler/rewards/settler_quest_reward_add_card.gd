class_name SettlerQuestReward_AddCard
extends SettlerQuestReward

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/add_card/event_outcome_widget_add_card.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var card_type: CardType

func grant(_quest: Quest_Settler, _run: Run) -> EventOutcomeWidget:
	assert(card_type)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_AddCard
	widget.card_type = card_type
	return widget

func describe() -> String:
	return tr('Get a %s <term_lower:glyph>.') % card_type.get_term_tag()
