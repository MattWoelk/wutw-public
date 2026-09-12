class_name Achievement_TotalRunsFinished
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.shard_settled.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.shard_settled.disconnect(check)

func check() -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(GlobalSaveGame.get_num_past_runs())
	# Achievement unlocked automatically based on stat range.
