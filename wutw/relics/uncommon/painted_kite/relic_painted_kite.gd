@tool
class_name Relic_PaintedKites
extends Relic

@export var desired_bonus_type: BonusType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_changed.unbind(3))
	_run.signals.bonus_lost.connect(_on_bonus_changed.unbind(3))
	_on_bonus_changed()

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_changed.unbind(3))
	_run.signals.bonus_lost.disconnect(_on_bonus_changed.unbind(3))
	super.on_removed()

func _on_bonus_changed() -> void:
	var max_bonus_amount: int = 0
	var amounts := _run.get_bonus_amounts()
	for bonus_type in amounts.get_bonus_types():
		var amount := amounts.get_amount(bonus_type)
		if amount > max_bonus_amount:
			max_bonus_amount = amount
	if amounts.get_amount(desired_bonus_type) == max_bonus_amount:
		_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, 1, _get_modifier_tag())
		_state = State.ACTIVE
	else:
		_run.get_vars().remove_modifier(_get_modifier_tag())
		_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % desired_bonus_type.get_term_tag()
