class_name Achievement_PacifiesPerTurn
extends Achievement_RunBase

var _pacifies_this_turn := 0

func on_run_entered(run: Run) -> void:
	run.signals.redraw_started.connect(_on_redraw_started)
	run.signals.haunting_pacified.connect(_on_haunting_pacified)

func on_run_exited(run: Run) -> void:
	run.signals.redraw_started.disconnect(_on_redraw_started)
	run.signals.haunting_pacified.disconnect(_on_haunting_pacified)

func _on_redraw_started(_is_first: bool) -> void:
	_pacifies_this_turn = 0

func _on_haunting_pacified(_haunting: HauntingBase) -> void:
	_pacifies_this_turn += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(_pacifies_this_turn)
	# Achievement unlocked automatically based on stat range.

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
