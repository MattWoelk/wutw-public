class_name Achievement_TotalHauntingsPacified
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.new_haunting_pacified.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.new_haunting_pacified.disconnect(check)

func check() -> void:
	var num_pacified := 0
	for haunting in GlobalSaveGame.get_seen_hauntings():
		if GlobalSaveGame.has_pacified_haunting(haunting):
			num_pacified += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_pacified)
	# Achievement unlocked automatically based on stat range.
