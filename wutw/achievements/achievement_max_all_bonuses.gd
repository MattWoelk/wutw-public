class_name Achievement_MaxAllBonuses
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.bonus_gained.connect(_on_bonus_gained)

func on_run_exited(run: Run) -> void:
	run.signals.bonus_gained.disconnect(_on_bonus_gained)

func _on_bonus_gained(_bonus_type: BonusType, _amount: int, _reason: BonusGain.Reason) -> void:
	check_in_run(Utils.get_active_run())

func check_in_run(run: Run) -> void:
	var min_bonus := 1_000_000
	var bonus_amounts := run.get_bonus_amounts()
	for bonus_type in BonusType.get_all_types():
		min_bonus = mini(min_bonus, bonus_amounts.get_amount(bonus_type))
	assert(min_bonus != 1_000_000)
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(min_bonus)
	# Achievement unlocked automatically based on stat range.
