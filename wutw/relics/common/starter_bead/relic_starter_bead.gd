@tool
class_name Relic_StarterBead
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.card_slotted.connect(_on_card_slotted)
	_run.signals.card_cast_finished.connect(_on_card_cast_finished)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	_run.signals.card_cast_finished.disconnect(_on_card_cast_finished)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	_on_card_cast_finished(card)

func _on_card_cast_finished(card: Card) -> void:
	if _state != State.ACTIVE:
		return
	_run.run_or_queue_action(func() -> void:
		if _state == State.ACTIVE:
			var stage := _run.get_current_stage()
			if not Utils.ensure(stage != null):
				return
			var deck := stage.get_card_deck()
			if not Utils.ensure(deck != null):
				return
			triggered.emit()
			await deck.add_card_to_hand(card.card_type, CardDeck.CardDrawReason.RELIC)
			_state = State.PASSIVE
	)
