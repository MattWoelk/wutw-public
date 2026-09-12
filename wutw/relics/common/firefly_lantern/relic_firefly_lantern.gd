@tool
class_name Relic_FireflyLantern
extends Relic

@export var granted_card: CardType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.redraw_finished.connect(_on_redraw_finished)

func on_removed() -> void:
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	super.on_removed()

func _on_redraw_finished(first: bool) -> void:
	if first:
		_run.run_or_queue_action(func() -> void:
			_state = State.ACTIVE
			var deck := _run.get_current_stage().get_card_deck()
			triggered.emit()
			await deck.add_card_to_hand(granted_card, CardDeck.CardDrawReason.RELIC)
			_state = State.PASSIVE
		)

func get_description() -> String:
	return tr(default_description) % granted_card.get_term_tag()
