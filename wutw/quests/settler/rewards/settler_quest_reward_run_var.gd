class_name SettlerQuestReward_RunVar
extends SettlerQuestReward

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var run_var: RunVars.Var
@export var delta: int
@export var preview_description: String
@export var outcome_description: String

func grant(quest: Quest_Settler, run: Run) -> EventOutcomeWidget:
	if not outcome_description:
		push_warning('Settler quest run_var reward has no outcome_description. Quest ID: ' + quest.quest_id)
	run.get_vars().add_modifier(run_var, delta, _get_mod_tag(quest))
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr(outcome_description)
	return widget

func describe() -> String:
	if not preview_description:
		push_warning('Settler quest run_var reward has no preview_description.')
	return tr(preview_description)
