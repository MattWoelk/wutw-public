@tool
class_name Relic_TuftOfHorsehair
extends Relic

@export var bonus_type: BonusType
@export var bonus_percentage: int = 10
@export var max_amount: int = 50

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_started.connect(_on_stage_started)

func on_removed() -> void:
	_run.signals.foray_started.disconnect(_on_stage_started)
	super.on_removed()

func _on_stage_started() -> void:
	var amount := mini(max_amount, roundi(
		_run.get_bonus_amounts().get_amount(bonus_type) * bonus_percentage / 100.0))
	if amount > 0:
		_state = State.ACTIVE
		triggered.emit()
		_run.gain_bonus(BonusGain.new(bonus_type, amount, self))
		await _brief_wait()
	_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % [bonus_percentage, bonus_type.get_term_tag(), max_amount]
