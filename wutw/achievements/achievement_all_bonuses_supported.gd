class_name Achievement_AllBonusesSupported
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.ability_finished.connect(_on_ability_finished)
	# WARNING: If other sources of focus/blessing are added, this should be updated.

func on_run_exited(run: Run) -> void:
	run.signals.ability_finished.disconnect(_on_ability_finished)

func _on_ability_finished(_card: Card, ability: CardAbility) -> void:
	if ability is not CardAbility_Support:
		return

	var run := Utils.get_active_run()
	for bonus_type in BonusType.get_all_types():
		if run.get_var(bonus_type.focus_var) <= 0:
			return
	# Passed all above - all must be blessed!
	achieved.emit()

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
