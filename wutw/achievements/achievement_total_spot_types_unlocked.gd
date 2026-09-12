class_name Achievement_TotalSpotTypesUnlocked
extends Achievement

func start_listening() -> void:
	GlobalSaveGame.spot_upgrade_discovered.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.spot_upgrade_discovered.disconnect(check)

func check() -> void:
	var num_spot_types_discovered := 0
	for spot_type in SpotType.get_all_spot_types():
		for upgrade in spot_type.get_all_upgrades():
			if GlobalSaveGame.has_seen_upgrade(upgrade):
				num_spot_types_discovered += 1
				break
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_spot_types_discovered)
	# Achievement unlocked automatically based on stat range.
