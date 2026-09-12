@tool
class_name Relic_BalanceCord
extends Relic

@export var harmony: BonusType
@export var adventure: BonusType
@export var heal_amount: int = 3
@export var hurt_amount: int = 3

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func _on_bonus_gained(bonus_type: BonusType, _amount: int, _reason: BonusGain.Reason) -> void:
	_run.run_or_queue_action(func() -> void:
		if bonus_type == harmony:
			triggered.emit()
			_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)
			await _brief_wait()
		elif bonus_type == adventure:
			triggered.emit()
			_run.modify_inspiration(-hurt_amount, Run.InspirationChangeReason.RELIC)
			await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % [heal_amount, hurt_amount]
