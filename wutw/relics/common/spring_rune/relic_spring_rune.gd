@tool
class_name Relic_SpringRune
extends Relic

@export var aspect: AspectType

@export var num_to_trigger: int = 2
@export var heal_amount: int = 10

var _activations_left_to_trigger: int

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.aspect_slot_filled.connect(_on_slot_filled)
	_activations_left_to_trigger = num_to_trigger

func on_removed() -> void:
	_run.signals.aspect_slot_filled.disconnect(_on_slot_filled)
	super.on_removed()

func get_current_counter() -> int:
	return num_to_trigger - _activations_left_to_trigger

func get_max_counter() -> int:
	return num_to_trigger

func save_data() -> Dictionary:
	var result := super.save_data()
	result['counter'] = _activations_left_to_trigger
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_activations_left_to_trigger = encoded_data.get('counter', num_to_trigger)

func _on_slot_filled(aspect_slot: AspectSlot) -> void:
	if aspect_slot.aspect_type == aspect:
		_activations_left_to_trigger -= 1
		if _activations_left_to_trigger == 0:
			_activations_left_to_trigger = num_to_trigger
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)
				await _brief_wait()
			)
	else:
		_activations_left_to_trigger = num_to_trigger
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % [num_to_trigger, heal_amount]
