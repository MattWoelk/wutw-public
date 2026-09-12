@tool
class_name Quest_Main120_Capital
extends Quest

@export var begin_dialogue: Dialogue
@export var end_dialogue: Dialogue
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.state_changed.connect(_on_run_state_changed.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.state_changed.disconnect(_on_run_state_changed.bind(instance, run))

func _on_run_state_changed(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	if instance.get_state() != QuestInstance.STATE_ACTIVE:
		return

	if run.get_state() == RunData.State.CAPITAL_PLACEMENT:
		if GlobalSaveGame.get_main_quest_progress() < SaveGame.MainQuestProgress.P118_REACHED_CONVERGENCE:
			GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P118_REACHED_CONVERGENCE)
	elif run.get_state() == RunData.State.HARMONIZATION:
		instance.set_goal_finished(0)
	elif run.get_state() == RunData.State.STAGE_SELECTOR:
		if run.get_current_season_index() > 0:
			instance.set_goal_finished(1)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		instance.start()
		GlobalSaveGame.save_game()
	elif instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P120_ESTABLISHED_CAPITAL)
		instance.finish(next_quest)
		GlobalSaveGame.save_game()
