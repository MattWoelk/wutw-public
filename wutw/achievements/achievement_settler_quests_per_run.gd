class_name Achievement_SettlerQuestsPerRun
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	GlobalSaveGame.quest_finished.connect(_on_quest_finished)
	check_in_run(run)

func on_run_exited(_run: Run) -> void:
	GlobalSaveGame.quest_finished.disconnect(_on_quest_finished)

func _on_quest_finished(quest_instance: QuestInstance) -> void:
	if quest_instance.get_quest() is not Quest_Settler:
		return
	check_in_run(Utils.get_active_run())

func check_in_run(_run: Run) -> void:
	var settler_quests_finished := 0
	for quest_instance in GlobalSaveGame.get_all_quest_instances():
		if quest_instance.is_finished() and quest_instance.get_quest() is Quest_Settler:
			settler_quests_finished += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(settler_quests_finished)
	# Achievement unlocked automatically based on stat range.
