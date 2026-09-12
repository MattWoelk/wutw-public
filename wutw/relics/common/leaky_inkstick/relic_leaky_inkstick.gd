@tool
class_name Relic_LeakyInkstick
extends Relic

@export var num_to_trigger: int = 4
@export var hand_size_increase: int = 2

# Not saved because it is only used within a single stage.
var _cards_played: int

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)
	_run.signals.card_cast_finished.connect(_on_card_cast)
	_run.signals.redraw_finished.connect(_on_redraw_finished)
	_cards_played = 0
	_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	_run.get_vars().remove_modifier(_get_modifier_tag())
	super.on_removed()

func get_current_counter() -> int:
	return _cards_played

func get_max_counter() -> int:
	return num_to_trigger

func _on_card_slotted(_card: Card, _aspect_slot: AspectSlot) -> void:
	_on_card_played()

func _on_card_cast(_card: Card) -> void:
	_on_card_played()

func _on_card_played() -> void:
	if _state == State.ACTIVE:
		_cards_played += 1
		counter_changed.emit()
		if _cards_played >= num_to_trigger:
			_run.run_or_queue_action(func() -> void:
				triggered.emit()
				var deck := _run.get_current_stage().get_card_deck()
				for card in deck.get_hand_cards():
					await deck.discard(card, CardDeck.DiscardReason.RELIC)
			)
			_state = State.PASSIVE

func _on_redraw_finished(_is_first: bool) -> void:
	_state = State.ACTIVE
	_cards_played = 0
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % [hand_size_increase, num_to_trigger]
