@tool
class_name Relic_HanamiMat
extends Relic

@export var triggering_bonus_type: BonusType
@export var heal_amount: int = 1

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func _on_bonus_gained(bonus_type: BonusType, _amount: int, _reason: BonusGain.Reason) -> void:
	if bonus_type == triggering_bonus_type:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % [triggering_bonus_type.get_term_tag(), heal_amount]
