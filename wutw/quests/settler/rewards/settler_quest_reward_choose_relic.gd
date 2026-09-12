class_name SettlerQuestReward_ChooseRelic
extends SettlerQuestReward

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/choose_relic/event_outcome_widget_choose_relic.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var relic_choice_pool: Array[Relic]

func grant(_quest: Quest_Settler, _run: Run) -> EventOutcomeWidget:
	assert(relic_choice_pool)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_ChooseRelic
	widget.relic_choice_pool = relic_choice_pool
	widget.ui_layer = UI.Layer.ANNOUNCEMENT_SUBMENU
	return widget

func describe() -> String:
	return tr('A choice of <term_lower:relic>s.')
