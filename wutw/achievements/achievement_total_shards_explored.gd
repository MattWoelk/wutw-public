class_name Achievement_TotalShardsExplored
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.settled_shard_explored.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.settled_shard_explored.disconnect(check)

func check() -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(GlobalSaveGame.get_num_explored_shards())
	# Achievement unlocked automatically based on stat range.
