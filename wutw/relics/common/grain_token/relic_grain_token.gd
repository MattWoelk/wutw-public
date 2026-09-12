@tool
class_name Relic_GrainToken
extends Relic

@export var bonus_threshold: int = 5

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.pre_bonus_gained.connect(_on_pre_bonus_gained)

func on_removed() -> void:
	_run.signals.pre_bonus_gained.disconnect(_on_pre_bonus_gained)
	super.on_removed()

func _on_pre_bonus_gained(gain: BonusGain) -> void:
	if gain.get_reason() == BonusGain.Reason.SPOT_RECIPE and gain.original_amount > 0 and gain.original_amount <= bonus_threshold:
		gain.amount *= 2
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % bonus_threshold
