class_name Achievement_FullSpots
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.foray_finished.connect(_on_stage_finished)

func on_run_exited(run: Run) -> void:
	run.signals.foray_finished.disconnect(_on_stage_finished)

func _on_stage_finished(settlement_state: SettlementState) -> void:
	var num_full_spots := 0
	for spot_upgrades in settlement_state.activated_upgrades:
		for upgrade: SpotUpgrade in spot_upgrades:
			if not upgrade.child_upgrades:
				num_full_spots += 1
				break
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_full_spots)
	# Achievement unlocked automatically based on stat range.

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
