@tool
class_name Relic_SoggyAcorn
extends Relic

@export var amount_gained: int = 5

const FOCUS_VARS := {
	RunVars.Var.FOCUS_FOOD: true,
	RunVars.Var.FOCUS_SAFETY: true,
	RunVars.Var.FOCUS_BEAUTY: true,
	RunVars.Var.FOCUS_HARMONY: true,
	RunVars.Var.FOCUS_KNOWLEDGE: true,
	RunVars.Var.FOCUS_ADVENTURE: true,
	RunVars.Var.FOCUS_PRODUCTIVITY: true,
}

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.get_vars().modified.connect(_on_vars_modified)

func on_removed() -> void:
	_run.get_vars().modified.disconnect(_on_vars_modified)
	super.on_removed()

func _on_vars_modified(type: RunVars.Var, old_value: int, new_value: int) -> void:
	if type not in FOCUS_VARS:
		return
	if new_value <= 0 or old_value > 0:
		return
	for bonus_type in BonusType.get_all_types():
		if bonus_type.focus_var == type:
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				_run.gain_bonus(BonusGain.new(bonus_type, amount_gained, self))
			)
			break

func get_description() -> String:
	var term := CardAbility_Support.new().get_term()
	return tr(default_description) % [term.get_term_id(), amount_gained]
