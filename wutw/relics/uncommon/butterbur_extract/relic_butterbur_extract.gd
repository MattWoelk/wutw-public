@tool
class_name Relic_ButterburExtract
extends Relic

@export var max_triggers: int = 7

var _num_triggers_this_stage: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.card_drawn.connect(_on_card_drawn)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.card_drawn.disconnect(_on_card_drawn)
	super.on_removed()

func get_current_counter() -> int:
	return _num_triggers_this_stage

func get_max_counter() -> int:
	return max_triggers

func _on_stage_started() -> void:
	_num_triggers_this_stage = 0
	_state = State.ACTIVE
	counter_changed.emit()

func _on_card_drawn(card: Card, _reason: CardDeck.CardDrawReason, from_discards: bool) -> void:
	if _num_triggers_this_stage >= max_triggers:
		return
	if from_discards:
		return
	if card.card_type.rarity != CardType.Rarity.NEGATIVE:
		return
	_num_triggers_this_stage += 1
	_run.run_or_queue_action(func() -> void:
		var deck := _run.get_current_stage().get_card_deck()
		counter_changed.emit()
		triggered.emit()
		while deck.is_redrawing():
			await _run.get_tree().process_frame
		await deck.draw(CardDeck.CardDrawReason.RELIC, true)
		if _num_triggers_this_stage >= max_triggers:
			_state = State.PASSIVE
	)

func get_description() -> String:
	return tr(default_description) % max_triggers
