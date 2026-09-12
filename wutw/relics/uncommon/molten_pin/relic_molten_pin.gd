@tool
class_name Relic_MoltenPin
extends Relic

@export var aspect: AspectType
@export var card_added: CardType
@export var num_slots_to_trigger: int = 3

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
	if aspect_slot.aspect_type == aspect:
		_slots_filled += 1
		if _slots_filled >= num_slots_to_trigger:
			_slots_filled = 0
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				var deck := _run.get_current_stage().get_card_deck()
				await deck.add_card_to_hand(card_added, CardDeck.CardDrawReason.RELIC)
			)
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % num_slots_to_trigger
