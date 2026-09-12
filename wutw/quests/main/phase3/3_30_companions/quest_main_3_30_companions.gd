@tool
class_name Quest_Main330_Companions
extends Quest

@export var end_dialogue: Dialogue
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.connect(_on_event_finished.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.disconnect(_on_event_finished.bind(instance, run))

func _on_event_finished(_event: Event, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if GlobalSaveGame.get_unlocked_companions():
		instance.set_goal_finished(0)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P330_BEFRIENDED_COMPANION)
		instance.finish(next_quest)
		GlobalSaveGame.save_game()
