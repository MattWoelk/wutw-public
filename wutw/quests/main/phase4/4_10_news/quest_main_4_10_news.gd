@tool
class_name Quest_Main410_News
extends Quest

@export var begin_dialogue: Dialogue
@export var abode_shard_type: ShardType
@export var next_quest: Quest

const STATE_DIALOGUE_SHOWN := 110

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		instance.start()
		GlobalSaveGame.save_game()

	if instance.get_state() < STATE_DIALOGUE_SHOWN:
		await GlobalUI.show_dialogue(begin_dialogue)
		instance.update_progress(STATE_DIALOGUE_SHOWN)
		GlobalSaveGame.save_game()

	GlobalSaveGame.changed.connect(_on_save_changed.bind(instance))

func on_hub_exited(instance: QuestInstance, _hub: Hub) -> void:
	GlobalSaveGame.changed.disconnect(_on_save_changed.bind(instance))

func _on_save_changed(instance: QuestInstance) -> void:
	if instance.is_finished():
		return

	if GlobalSaveGame.is_shard_explored(GlobalSaveGame.get_past_run_by_shard_type(abode_shard_type).uid):
		instance.set_goal_finished(0)

	if instance.is_ready_to_finish():
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P410_FOUND_KID)
		instance.finish(next_quest, false)
		GlobalSaveGame.save_game()
