@tool
class_name Relic_RosaryRing
extends Relic

@export var num_cards_to_trigger: int = 4

var _cards_played: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	super.on_removed()

func get_current_counter() -> int:
	return _cards_played

func get_max_counter() -> int:
	return num_cards_to_trigger

func save_data() -> Dictionary:
	var result := super.save_data()
	result['counter'] = _cards_played
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_cards_played = encoded_data.get('counter', 0)

func _on_card_slotted(_card: Card, aspect_slot: AspectSlot) -> void:
	if not Utils.get_typed_ancestor(aspect_slot, SpotRecipe):
		return
	_cards_played += 1
	if _cards_played >= num_cards_to_trigger:
		var deck := _run.get_current_stage().get_card_deck()
		_cards_played = 0
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await deck.draw(CardDeck.CardDrawReason.RELIC, true)
		)
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % num_cards_to_trigger
