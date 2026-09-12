class_name Achievement_PerfectHarmonization
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.harmonization_finished.connect(_on_harmonization_finished)

func on_run_exited(run: Run) -> void:
	run.signals.harmonization_finished.disconnect(_on_harmonization_finished)

func _on_harmonization_finished() -> void:
	for settlement in Utils.get_active_run().get_settlements():
		if not settlement.is_settlement_connected() or settlement.get_unsatisfied_lacks():
			return
	achieved.emit()

func check_in_run(_run: Run) -> void:
	return  # Can't be checked retroactively.
