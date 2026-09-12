class_name Tutorial_Negative_Bonuses
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.bonus_lost.connect(_on_bonus_lost)

func stop_listening() -> void:
	Utils.get_active_run().signals.bonus_lost.disconnect(_on_bonus_lost)

func _on_bonus_lost(bonus_type: BonusType, _amount: int, _reason: BonusGain.Reason) -> void:
	var run := Utils.get_active_run()
	if run.get_bonus_amounts().get_amount(bonus_type) < 0:
		if run.get_var(RunVars.Var.INSPIRATION_LOST_PER_NEGATIVE_BONUS):  # If unmitigated.
			ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var shortage_type: BonusType
	for bonus_type in BonusType.get_all_types():
		if run.get_bonus_amounts().get_amount(bonus_type) < 0:
			shortage_type = bonus_type
			break
	assert(shortage_type)
	var text := tr('''
The shard is now experiencing a global shortage of %s. For each type of <term_lower:bonus> that is
below zero at the end of a <term_lower:foray>, the expedition will lose %d <term:inspiration>.
''').strip_edges() % [
	shortage_type.get_term_tag(), run.get_var(RunVars.Var.INSPIRATION_LOST_PER_NEGATIVE_BONUS)
]
	var panel := run.get_run_bonus_listing().get_child(0) as Control
	_outline_controls([panel])
	_show_tooltip(panel, text, [Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'negative_bonuses'
