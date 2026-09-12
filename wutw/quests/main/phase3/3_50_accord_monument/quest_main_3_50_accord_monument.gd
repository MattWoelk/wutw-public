@tool
class_name Quest_Main350_AccordMonument
extends Quest

@export var end_dialogue: Dialogue

func on_run_entered(instance: QuestInstance, _run: Run) -> void:
	GlobalSaveGame.changed.connect(_on_savegame_changed.bind(instance))
	_on_savegame_changed(instance)  # In case the game was reloaded.

func on_run_exited(instance: QuestInstance, _run: Run) -> void:
	GlobalSaveGame.changed.disconnect(_on_savegame_changed.bind(instance))

func _on_savegame_changed(instance: QuestInstance) -> void:
	assert(instance)
	if instance.is_finished():
		return
	if not instance.is_ready_to_finish():
		if GlobalSaveGame.get_events_state().get_bool_or_default('global', 'accord_monument_built', false):
			await GlobalUI.show_dialogue(end_dialogue)
			instance.set_goal_finished(0)
			GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P350_SIGNED_ACCORD)
			instance.finish(null)
			GlobalSaveGame.save_game()
