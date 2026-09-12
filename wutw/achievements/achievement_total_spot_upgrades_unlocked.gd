class_name Achievement_TotalSpotUpgradesUnlocked
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.spot_upgrade_discovered.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.spot_upgrade_discovered.disconnect(check)

func check() -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(GlobalSaveGame.get_num_seen_upgrades())
	# Achievement unlocked automatically based on stat range.
