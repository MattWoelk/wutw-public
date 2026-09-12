@tool
class_name Relic_AncientBone
extends Relic

@export var trigger_bonus_type: BonusType
@export var granted_bonus_type: BonusType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_lost.connect(_on_bonus_lost)

func on_removed() -> void:
	_run.signals.bonus_lost.disconnect(_on_bonus_lost)
	super.on_removed()

func _on_bonus_lost(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	_run.run_or_queue_action(func() -> void:
		if bonus_type == trigger_bonus_type:
			triggered.emit()
			_run.gain_bonus(BonusGain.new(granted_bonus_type, 2 * amount, self))
			await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % [trigger_bonus_type.get_term_tag(), granted_bonus_type.get_term_tag()]
