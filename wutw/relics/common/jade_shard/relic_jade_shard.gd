@tool
class_name Relic_JadeShard
extends Relic

@export var amount_granted: int = 20

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_started.connect(_on_bonuses_changed)
	_run.signals.bonus_gained.connect(_on_bonuses_changed.unbind(3))
	_run.signals.bonus_lost.connect(_on_bonuses_changed.unbind(3))
	_run.signals.before_foray_finished.connect(_on_before_foray_finished)

func on_removed() -> void:
	_run.signals.foray_started.disconnect(_on_bonuses_changed)
	_run.signals.bonus_gained.disconnect(_on_bonuses_changed.unbind(3))
	_run.signals.bonus_lost.disconnect(_on_bonuses_changed.unbind(3))
	_run.signals.before_foray_finished.disconnect(_on_before_foray_finished)
	super.on_removed()

func _on_before_foray_finished(settlement_state: SettlementState) -> void:
	var num_unsatisfied := settlement_state.goal.get_remaining_requirements(
		_run.get_current_stage().get_stage_bonus_amounts()).size()
	if num_unsatisfied == settlement_state.goal.get_num_requirements():
		# Must be synchronous as the stage is getting deleted.
		triggered.emit()
		for bonus_type in BonusType.get_all_types():
			_run.gain_bonus(BonusGain.new(bonus_type, amount_granted, self))
		await _brief_wait()

func _on_bonuses_changed() -> void:
	var stage := _run.get_current_stage()
	if stage and stage.get_goal().get_remaining_requirements(stage.get_stage_bonus_amounts()):
		_state = State.ACTIVE
	else:
		_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % amount_granted
