@tool
class_name Quest_Main125_Crafting
extends Quest

@export var end_dialogue: Dialogue
@export var next_quest: Quest

func instantiate(initial_state: int = QuestInstance.STATE_ACTIVE, initial_goals_completed: Array[bool] = []) -> QuestInstance:
	var instance := super.instantiate(initial_state, initial_goals_completed)
	if not instance.is_finished():
		if GlobalSaveGame.changed.is_connected(_handle_savegame_changed.bind(instance)):
			# HACK: When we load savegames to list slots, this gets bound and not cleared.
			# It refuses to rebind event if the instance is different.
			GlobalSaveGame.changed.disconnect(_handle_savegame_changed.bind(instance))
		GlobalSaveGame.changed.connect(_handle_savegame_changed.bind(instance))
		_handle_savegame_changed(instance)
	return instance

func _handle_savegame_changed(instance: QuestInstance) -> void:
	if not instance: return  # Freed

	if not instance.is_goal_completed(0):
		if Skill.get_skill_var(Skill.Var.INSCRIBE_COMMON):
			instance.set_goal_finished(0)
			GlobalSaveGame.save_game()

	if not instance.is_goal_completed(1):
		var auto_unlocked_cards := SaveGame.get_starter_cards()
		auto_unlocked_cards.append_array(SaveGame.get_auto_unlocked_cards())
		for card_type in GlobalSaveGame.get_unlocked_cards():
			if card_type not in auto_unlocked_cards:
				instance.set_goal_finished(1)
				GlobalSaveGame.save_game()
				break

	if instance.is_ready_to_finish():
		GlobalSaveGame.changed.disconnect(_handle_savegame_changed.bind(instance))
		await GlobalUI.show_dialogue(end_dialogue)
		instance.finish(next_quest)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P125_CRAFTED_GLYPH)
		GlobalSaveGame.save_game()
