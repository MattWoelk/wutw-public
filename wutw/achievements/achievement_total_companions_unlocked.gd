class_name Achievement_TotalCompanionsUnlocked
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.companion_unlocked.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.companion_unlocked.disconnect(check)

func check() -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(GlobalSaveGame.get_num_unlocked_companions())
	# Achievement unlocked automatically based on stat range.
