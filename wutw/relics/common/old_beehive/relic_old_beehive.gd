@tool
class_name Relic_OldBeehive
extends Relic

@export var bonus_type: BonusType
@export var amount_to_trigger: int
@export var granted_card_type: CardType

var _bonus_accumulated: int = 0
var _triggered_this_turn := false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)
	_run.signals.redraw_finished.connect(_on_redraw_finished)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	super.on_removed()

func get_current_counter() -> int:
	return _bonus_accumulated

func get_max_counter() -> int:
	return amount_to_trigger

func save_data() -> Dictionary:
	var result := super.save_data()
	result['counter'] = _bonus_accumulated
	result['triggered_this_turn'] = _triggered_this_turn
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_bonus_accumulated = encoded_data.get('counter', 0)
	_triggered_this_turn = encoded_data.get('triggered_this_turn', false)

func _on_bonus_gained(gained_bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	var stage := _run.get_current_stage()
	if not stage:
		return

	if gained_bonus_type == bonus_type and amount > 0:
		_bonus_accumulated += amount
		if _bonus_accumulated >= amount_to_trigger:
			if _triggered_this_turn:
				_bonus_accumulated = amount_to_trigger
			else:
				_bonus_accumulated = min(amount_to_trigger, _bonus_accumulated - amount_to_trigger)
				_triggered_this_turn = true
				_run.run_or_queue_action(func() -> void:
					triggered.emit()
					await stage.get_card_deck().add_card_to_hand(granted_card_type, CardDeck.CardDrawReason.RELIC)
					_state = State.PASSIVE
				)
		counter_changed.emit()

func _on_redraw_finished(_is_first: bool) -> void:
	var stage := _run.get_current_stage()
	if not stage:
		return

	if _bonus_accumulated >= amount_to_trigger:
		_bonus_accumulated = 0
		counter_changed.emit()
		_triggered_this_turn = true
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await stage.get_card_deck().add_card_to_hand(granted_card_type, CardDeck.CardDrawReason.RELIC)
			_state = State.PASSIVE
		)
	else:
		_triggered_this_turn = false
		_state = State.ACTIVE

func get_description() -> String:
	return tr(default_description) % [
			amount_to_trigger, bonus_type.get_term_tag(), granted_card_type.get_term_tag()]
