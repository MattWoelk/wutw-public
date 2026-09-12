@tool
class_name Quest_Main117_Surveys
extends Quest

@export var begin_dialogue: Dialogue
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.state_changed.connect(_on_state_changed.bind(instance, run))
	_check_to_start(instance)

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.state_changed.disconnect(_on_state_changed.bind(instance, run))

func _on_state_changed(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	if run.get_state() == RunData.State.SURVEY_END and not instance.is_finished():
		instance.set_goal_finished(0)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P117_COMPLETED_SURVEY)
		instance.finish(next_quest, false)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	_check_to_start(instance)

func _check_to_start(instance: QuestInstance) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		instance.start()
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P116_UNLOCKED_SURVEY)
		GlobalSaveGame.save_game()
	elif GlobalSaveGame.get_main_quest_progress() < SaveGame.MainQuestProgress.P116_UNLOCKED_SURVEY:
		# For upgrading old savegames.
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P116_UNLOCKED_SURVEY)
		GlobalSaveGame.save_game()
