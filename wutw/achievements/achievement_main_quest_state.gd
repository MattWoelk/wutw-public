class_name Achievement_MainQuestState
extends Achievement

@export var min_mq_state: SaveGame.MainQuestProgress

func start_listening() -> void:
	GlobalSaveGame.main_quest_state_changed.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.main_quest_state_changed.disconnect(check)

func check() -> void:
	if GlobalSaveGame.get_main_quest_progress() >= min_mq_state:
		achieved.emit()
