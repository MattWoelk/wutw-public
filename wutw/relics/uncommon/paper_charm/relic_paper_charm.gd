@tool
class_name Relic_PaperCharm
extends Relic

@export var card_added: CardType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.redraw_finished.connect(_on_redrew)

func on_removed() -> void:
	_run.signals.redraw_finished.disconnect(_on_redrew)
	super.on_removed()

func _on_redrew(is_first: bool) -> void:
	if not is_first:
		var deck := _run.get_current_stage().get_card_deck()
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await deck.add_card_to_hand(card_added, CardDeck.CardDrawReason.HARMONIZATION_RECIPE)
		)
