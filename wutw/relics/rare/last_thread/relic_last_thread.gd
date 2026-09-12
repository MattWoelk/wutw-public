@tool
class_name Relic_LastThread
extends Relic

@export var max_times_per_hand: int = 2

var _times_triggered_this_hand := 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)
	_run.signals.card_cast_finished.connect(_on_card_cast)
	_run.signals.redraw_started.connect(_on_redraw_started)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	_run.signals.redraw_started.disconnect(_on_redraw_started)
	super.on_removed()

func get_current_counter() -> int:
	return _times_triggered_this_hand

func get_max_counter() -> int:
	return max_times_per_hand

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	_on_card_played(card)

func _on_card_cast(card: Card) -> void:
	_on_card_played(card)

func _on_card_played(_card: Card) -> void:
	_run.run_or_queue_action(func() -> void:
		var deck := _run.get_current_stage().get_card_deck()
		if deck.get_hand_cards().is_empty():
			if _times_triggered_this_hand < max_times_per_hand:
				_times_triggered_this_hand += 1
				counter_changed.emit()
				triggered.emit()
				await deck.draw(CardDeck.CardDrawReason.RELIC, true)
			if _times_triggered_this_hand >= max_times_per_hand:
				_state = State.PASSIVE
	)

func _on_redraw_started(_is_first: bool) -> void:
	_times_triggered_this_hand = 0
	counter_changed.emit()
	_state = State.ACTIVE

func get_description() -> String:
	return tr(default_description) % max_times_per_hand
