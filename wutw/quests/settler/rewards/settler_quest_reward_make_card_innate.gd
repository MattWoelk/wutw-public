class_name SettlerQuestReward_MakeCardInnate
extends SettlerQuestReward

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/make_card_innate/event_outcome_widget_make_card_innate.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

func grant(_quest: Quest_Settler, _run: Run) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_MakeCardInnate
	widget.ui_layer = UI.Layer.ANNOUNCEMENT_SUBMENU
	return widget

func describe() -> String:
	return tr('Make a <term_lower:glyph> <term_lower:innate>.')
