@tool
class_name Relic_OddStatue
extends Relic

@export var aspect_type: AspectType
@export var num_slots_to_trigger: int = 3
@export var bonus_type: BonusType
@export var amount_gained: int = 10

var _slots_filled: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.aspect_slot_filled.connect(_on_slot_filled)

func on_removed() -> void:
	_run.signals.aspect_slot_filled.disconnect(_on_slot_filled)
	super.on_removed()

func get_current_counter() -> int:
	return _slots_filled

func get_max_counter() -> int:
	return num_slots_to_trigger

func save_data() -> Dictionary:
	var result := super.save_data()
	result['counter'] = _slots_filled
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_slots_filled = encoded_data.get('counter', 0)

func _on_slot_filled(aspect_slot: AspectSlot) -> void:
	if aspect_slot.aspect_type == aspect_type:
		_slots_filled += 1
		if _slots_filled >= num_slots_to_trigger:
			_slots_filled = 0
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				_run.gain_bonus(BonusGain.new(bonus_type, amount_gained, self))
				await _brief_wait()
			)
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % [num_slots_to_trigger, aspect_type.get_term_tag(), amount_gained, bonus_type.get_term_tag()]
