@tool
class_name Relic_IndecipherableSchematic
extends Relic

@export var bonus_type: BonusType
@export var amount_required: int = 150
@export var max_inspiration_gained: int = 10

var _amount_collected: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	# The player gets to keep the one-time maximum modifier.
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func get_current_counter() -> int:
	return _amount_collected

func save_data() -> Dictionary:
	var result := super.save_data()
	result['amount_collected'] = _amount_collected
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_amount_collected = encoded_data.get('amount_collected', 0)

func _on_bonus_gained(gained_bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if _state != State.ACTIVE or gained_bonus_type != bonus_type:
		return
	_run.run_or_queue_action(func() -> void:
		_amount_collected += amount
		if _amount_collected >= amount_required:
			# Gets persisted independently from the relic.
			_run.get_vars().add_modifier(RunVars.Var.MAX_INSPIRATION, max_inspiration_gained, _get_modifier_tag())
			_amount_collected = 0
			_state = State.EXPIRED
			triggered.emit()
			await _brief_wait()
		counter_changed.emit()
	)

func get_description() -> String:
	return tr(default_description) % [amount_required, bonus_type.get_term_tag(), max_inspiration_gained]
