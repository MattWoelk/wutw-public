class_name Achievement_SlotsPerTurn
extends Achievement_RunBase

var _slots_filled_this_turn := 0

func on_run_entered(run: Run) -> void:
	run.signals.redraw_started.connect(_on_redraw_started)
	run.signals.aspect_slot_filled.connect(_on_slot_filled)

func on_run_exited(run: Run) -> void:
	run.signals.redraw_started.disconnect(_on_redraw_started)
	run.signals.aspect_slot_filled.disconnect(_on_slot_filled)

func _on_redraw_started(_is_first: bool) -> void:
	_slots_filled_this_turn = 0

func _on_slot_filled(_aspect_slot: AspectSlot) -> void:
	_slots_filled_this_turn += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(_slots_filled_this_turn)
	# Achievement unlocked automatically based on stat range.

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
