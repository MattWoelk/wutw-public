@tool
class_name Relic_RecordOfRuin
extends Relic

@export var triggering_bonus_type: BonusType
@export var added_bonus_type: BonusType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func _on_bonus_gained(gained_bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if gained_bonus_type == triggering_bonus_type and amount > 0:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_run.gain_bonus(BonusGain.new(added_bonus_type, floori(amount / 2.0), self))
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % [
			triggering_bonus_type.get_term_tag(), added_bonus_type.get_term_tag()]
