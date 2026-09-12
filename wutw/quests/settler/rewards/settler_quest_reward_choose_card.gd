class_name SettlerQuestReward_ChooseCard
extends SettlerQuestReward

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/choose_card/event_outcome_widget_choose_card.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var card_tier_bonus: int = 0

func grant(_quest: Quest_Settler, _run: Run) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_ChooseCard
	widget.card_tier_bonus = card_tier_bonus
	widget.ui_layer = UI.Layer.ANNOUNCEMENT_SUBMENU
	return widget

func describe() -> String:
	return tr('Get a choice of high rarity <term_lower:glyph>s.')
