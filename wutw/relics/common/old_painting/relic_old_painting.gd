@tool
class_name Relic_OldPainting
extends Relic

@export var consumed_bonus_type: BonusType
@export var amount_required: int = 50
@export var granted_card: CardType

var _bonus_accumulated: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_lost.connect(_on_bonus_lost)
	_run.signals.redraw_finished.connect(_on_redraw_finished)

func on_removed() -> void:
	_run.signals.bonus_lost.disconnect(_on_bonus_lost)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	super.on_removed()

func get_current_counter() -> int:
	return _bonus_accumulated

func get_max_counter() -> int:
	return amount_required

func save_data() -> Dictionary:
	var result := super.save_data()
	result['counter'] = _bonus_accumulated
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_bonus_accumulated = encoded_data.get('counter', 0)

func _on_bonus_lost(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if _bonus_accumulated >= amount_required:
		return
	if bonus_type == consumed_bonus_type:
		_bonus_accumulated = mini(amount_required, _bonus_accumulated + amount)
		counter_changed.emit()

func _on_redraw_finished(first: bool) -> void:
	if _bonus_accumulated < amount_required:
		return
	if first:
		_run.run_or_queue_action(func() -> void:
			_state = State.ACTIVE
			var deck := _run.get_current_stage().get_card_deck()
			triggered.emit()
			await deck.add_card_to_hand(granted_card, CardDeck.CardDrawReason.RELIC)
			_state = State.PASSIVE
		)

func get_description() -> String:
	return tr(default_description) % [
		amount_required, consumed_bonus_type.get_term_tag(), granted_card.get_term_tag()]
