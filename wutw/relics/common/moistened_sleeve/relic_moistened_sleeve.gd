@tool
class_name Relic_MoistenedSleeve
extends Relic

@export var bonus_type: BonusType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.inspiration_lost.connect(_on_inspiration_lost)

func on_removed() -> void:
	_run.signals.inspiration_lost.disconnect(_on_inspiration_lost)
	super.on_removed()

func _on_inspiration_lost(amount: int, _reason: Run.InspirationChangeReason) -> void:
	var amount_granted := amount * 2
	_run.run_or_queue_action(func() -> void:
		triggered.emit()
		_run.gain_bonus(BonusGain.new(bonus_type, amount_granted, self))
		await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % bonus_type.get_term_tag()
