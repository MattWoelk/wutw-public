@tool
class_name EventOutcome_StartQuest
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/event_outcome_widget_message.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var quest: Quest

func apply(_event: Event) -> EventOutcomeWidget:
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Message
	widget.text = tr('Quest started: ') + tr(quest.name)
	widget.finished.connect(func() -> void:
		var quest_instance := quest.instantiate(QuestInstance.STATE_INACTIVE)
		GlobalSaveGame.add_quest_instance(quest_instance)
		quest_instance.start()
	, CONNECT_ONE_SHOT)
	return widget

func describe(_run: Run) -> String:
	return tr('Start quest: ') + tr(quest.name)
