@tool
class_name Quest_Main220_Hauntings
extends Quest

@export var num_required: int = 3
@export var end_dialogue: Dialogue
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.haunting_pacified.connect(_on_haunting_pacified.bind(instance))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.haunting_pacified.disconnect(_on_haunting_pacified.bind(instance))

func _on_haunting_pacified(_haunting: HauntingBase, instance: QuestInstance) -> void:
	_check_hauntings(instance)

func _check_hauntings(instance: QuestInstance) -> void:
	if _get_num_pacified() >= num_required:
		instance.set_goal_finished(0)

func _get_num_pacified() -> int:
	var num_pacified := 0
	for haunting_type in GlobalSaveGame.get_seen_hauntings():
		if GlobalSaveGame.has_pacified_haunting(haunting_type):
			num_pacified += 1
	return num_pacified

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	_check_hauntings(instance)
	if instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P220_HAUNTINGS_STUDIED)
		instance.finish(next_quest)
		GlobalSaveGame.save_game()

func get_decorated_goals() -> Array[String]:
	return [tr('[%d/%d] %s') % [_get_num_pacified(), num_required, tr(goals[0])]]
