@tool
class_name Relic_JadeBead
extends Relic

@export var triggering_bonus_type: BonusType
@export var extra_percent: int = 50
@export var lost_bonus_type: BonusType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.pre_bonus_gained.connect(_on_pre_bonus_gained)

func on_removed() -> void:
	_run.signals.pre_bonus_gained.disconnect(_on_pre_bonus_gained)
	super.on_removed()

func _on_pre_bonus_gained(gain: BonusGain) -> void:
	if gain.bonus_type == triggering_bonus_type:
		# pre_bonus_gained() must have a synchronous effect.
		triggered.emit()
		var extra_amount := roundi(gain.amount * (extra_percent / 100.0))
		gain.amount += extra_amount
		_run.run_or_queue_action(func() -> void:
			_run.gain_bonus(BonusGain.new(lost_bonus_type, -extra_amount, self))
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % [triggering_bonus_type.get_term_tag(), extra_percent, lost_bonus_type.get_term_tag()]
