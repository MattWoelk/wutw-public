class_name SettlerQuestReward_RecallCard
extends SettlerQuestReward

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/recall_cards/event_outcome_widget_recall_card.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func grant(_quest: Quest_Settler, _run: Run) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_RecallCard
	widget.ui_layer = UI.Layer.ANNOUNCEMENT_SUBMENU
	return widget

func describe() -> String:
	return tr('Choose an <term_lower:craft>d <term_lower:glyph> to <term_lower:add_card> to your <term_lower:card_deck>.')
