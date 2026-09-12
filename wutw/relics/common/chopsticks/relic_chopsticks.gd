@tool
class_name Relic_Chopsticks
extends Relic

@export var num_to_trigger: int = 2
@export var bonus_type: BonusType
@export var gain_amount: int = 10

# Not saved because it's only used within a stage.
var _streak: int
var _streak_type: AspectType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.aspect_slot_filled.connect(_on_slot_filled)
	_streak = 0

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.aspect_slot_filled.disconnect(_on_slot_filled)
	super.on_removed()

func get_current_counter() -> int:
	return _streak

func get_max_counter() -> int:
	return num_to_trigger

func _on_stage_started() -> void:
	_streak = 0
	_streak_type = null
	counter_changed.emit()

func _on_slot_filled(aspect_slot: AspectSlot) -> void:
	if aspect_slot.is_universal:
		_streak = 0
		_streak_type = null
	elif _streak_type == aspect_slot.aspect_type:
		_streak += 1
		if _streak >= num_to_trigger:
			_streak = 0
			_streak_type = null
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				_run.gain_bonus(BonusGain.new(bonus_type, gain_amount, self))
				await _brief_wait()
			)
	else:
		_streak = 1
		_streak_type = aspect_slot.aspect_type
	counter_changed.emit()

func get_description() -> String:
	var description := tr(default_description) % [num_to_trigger, gain_amount, bonus_type.get_term_tag()]
	if _streak_type:
		description += '\n\n'
		description += tr('Current <term:aspect>: %s') % _streak_type.get_term_tag()
	return description
