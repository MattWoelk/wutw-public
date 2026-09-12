class_name Achievement_IgnoredHauntings
extends Achievement_RunBase

@export var min_desired: int = 2

var _num_hauntings_left := -1

func on_run_entered(run: Run) -> void:
	run.signals.foray_started.connect(_on_stage_started)
	run.signals.haunting_pacified.connect(_on_haunting_pacified)
	run.signals.foray_finished.connect(_on_stage_finished)

func on_run_exited(run: Run) -> void:
	run.signals.foray_started.disconnect(_on_stage_started)
	run.signals.haunting_pacified.disconnect(_on_haunting_pacified)
	run.signals.foray_finished.disconnect(_on_stage_finished)

func _on_stage_started() -> void:
	_num_hauntings_left = Utils.get_active_run().get_current_stage().get_hauntings().size()

func _on_haunting_pacified(_haunting: HauntingBase) -> void:
	_num_hauntings_left -= 1

func _on_stage_finished(settlement_state: SettlementState) -> void:
	if _num_hauntings_left < min_desired:
		return
	if not settlement_state.goal:  # Harmonization
		return
	if settlement_state.goal.get_remaining_requirements(settlement_state.bonus_amounts).is_empty():
		achieved.emit()

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
