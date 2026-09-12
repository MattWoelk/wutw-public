class_name Achievement_NumSettlements
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.foray_finished.connect(_on_stage_finished)

func on_run_exited(run: Run) -> void:
	run.signals.foray_finished.disconnect(_on_stage_finished)

func _on_stage_finished(_settlement_state: SettlementState) -> void:
	var num_settlements := 1 + Utils.get_active_run().get_settlement_states().size()
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_settlements)
	# Achievement unlocked automatically based on stat range.

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
