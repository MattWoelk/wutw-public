@tool
class_name Quest_Main320_WildMonastery
extends Quest

@export var wilds_shard: ShardType
@export var wild_monastery: SpotUpgrade
@export var end_dialogue: Dialogue
@export var next_quest: Quest

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.is_active() and GlobalSaveGame.is_shard_type_unlocked(wilds_shard):
		await GlobalUI.show_dialogue(end_dialogue)
		instance.set_goal_finished(0)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P320_ESTABLISHED_MONASTERY)
		instance.finish(next_quest)
		GlobalSaveGame.save_game()

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [wild_monastery]
