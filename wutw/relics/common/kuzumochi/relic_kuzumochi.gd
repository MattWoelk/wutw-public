@tool
class_name Relic_Kuzumochi
extends Relic

@export var triggering_bonus: BonusType
@export var amount_to_trigger: int = 10
@export var heal_amount: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func _on_bonus_gained(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if bonus_type == triggering_bonus and amount >= amount_to_trigger:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _brief_wait()
			_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)
		)

func get_description() -> String:
	return tr(default_description) % [amount_to_trigger, triggering_bonus.get_term_tag(), heal_amount]
