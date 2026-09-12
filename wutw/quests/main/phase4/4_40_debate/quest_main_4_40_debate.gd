@tool
class_name Quest_Main440_Debate
extends Quest

@export var begin_dialogue: Dialogue

@export var starting_arguments: Array[DebateArgument]
@export var talisman_arguments: Dictionary[Relic, DebateArgument]
@export var doubts_threshold: int = 3
@export var doubts_dialogue: Dialogue

@export var teo_diary_threshold: int = 6
@export var teo_diary_dialogue: Dialogue

@export var translated_threshold: int = 7
@export var translated_dialogue: Dialogue
@export var translated_record: HistoricalRecord

@export var abdication_threshold: int = 9
@export var abdication_dialogue: Dialogue
@export var final_argument: DebateArgument

const STATE_DOUBTS_EXPRESSED: int = 110
const STATE_DIARY_GIVEN: int = 120
const STATE_TRANSLATION_RETURNED: int = 130
const STATE_FINAL_ARGUMENT_GIVEN: int = 140

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P430_STARTED_DEBATE)
		instance.start()
		for argument in starting_arguments:
			GlobalSaveGame.unlock_argument(argument)
		for relic in talisman_arguments:
			if GlobalSaveGame.has_seen_relic(relic):
				GlobalSaveGame.unlock_argument(talisman_arguments[relic])
				break  # In case we have multiple talismans unlocked somehow.
		GlobalSaveGame.save_game()

	GlobalSaveGame.changed.connect(_on_save_changed.bind(instance))

func on_hub_exited(instance: QuestInstance, _hub: Hub) -> void:
	GlobalSaveGame.changed.disconnect(_on_save_changed.bind(instance))

func _on_save_changed(instance: QuestInstance) -> void:
	if instance.is_finished():
		return

	var historian := 0
	for argument: DebateArgument in DebateArgument.get_all_arguments().values():
		if GlobalSaveGame.is_argument_used(argument) and argument.faction == DebateArgument.Faction.HISTORIAN:
			historian += argument.impact

	if instance.get_state() < STATE_DOUBTS_EXPRESSED and historian >= doubts_threshold:
		await GlobalUI.show_dialogue(doubts_dialogue)
		instance.update_progress(STATE_DOUBTS_EXPRESSED)
		GlobalSaveGame.save_game()
		return

	if instance.get_state() < STATE_DIARY_GIVEN and historian >= teo_diary_threshold:
		await GlobalUI.show_dialogue(teo_diary_dialogue)
		instance.update_progress(STATE_DIARY_GIVEN)
		GlobalSaveGame.save_game()
		return

	if instance.get_state() < STATE_TRANSLATION_RETURNED and historian >= translated_threshold:
		await GlobalUI.show_dialogue(translated_dialogue)
		instance.update_progress(STATE_TRANSLATION_RETURNED)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P435_TRANSLATED_COMMANDMENTS)
		MuseumBrowser.open_museum_entry(translated_record, UI.Layer.GAME_MENU)
		GlobalSaveGame.save_game()
		return

	if instance.get_state() < STATE_FINAL_ARGUMENT_GIVEN and historian >= abdication_threshold:
		await GlobalUI.show_dialogue(abdication_dialogue)
		GlobalSaveGame.unlock_argument(final_argument)
		instance.update_progress(STATE_FINAL_ARGUMENT_GIVEN)
		GlobalSaveGame.save_game()
		return

	if GlobalSaveGame.is_argument_used(final_argument):
		instance.set_goal_finished(0)
		instance.finish(null)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P440_FINISHED_DEBATE)
		GlobalSaveGame.game_finished.emit()
		return
