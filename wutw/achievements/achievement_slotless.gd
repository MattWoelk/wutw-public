class_name Achievement_Slotless
extends Achievement_RunBase

var _filled_slots_this_stage := false

func on_run_entered(run: Run) -> void:
	run.signals.foray_started.connect(_on_stage_started)
	run.signals.foray_finished.connect(_on_stage_finished)
	run.signals.aspect_slot_filled.connect(_on_slot_filled)

func on_run_exited(run: Run) -> void:
	run.signals.foray_started.disconnect(_on_stage_started)
	run.signals.foray_finished.disconnect(_on_stage_finished)
	run.signals.aspect_slot_filled.disconnect(_on_slot_filled)

func _on_stage_started() -> void:
	_filled_slots_this_stage = false

func _on_slot_filled(_aspect_slot: AspectSlot) -> void:
	_filled_slots_this_stage = true

func _on_stage_finished(settlement_state: SettlementState) -> void:
	if _filled_slots_this_stage:
		return
	if not settlement_state.goal:  # Harmonization
		return
	if settlement_state.goal.get_remaining_requirements(settlement_state.bonus_amounts).is_empty():
		achieved.emit()

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
