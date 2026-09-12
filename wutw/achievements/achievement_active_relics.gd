class_name Achievement_ActiveRelics
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.relic_added.connect(_on_relic_added)

func on_run_exited(run: Run) -> void:
	run.signals.relic_added.disconnect(_on_relic_added)

func _on_relic_added(_relic: Relic) -> void:
	check_in_run(Utils.get_active_run())

func check_in_run(run: Run) -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(run.get_current_relics().size())
	# Achievement unlocked automatically based on stat range.
