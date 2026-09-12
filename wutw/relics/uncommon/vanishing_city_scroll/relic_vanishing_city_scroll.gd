@tool
class_name Relic_VanishingCityScroll
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.redraw_finished.connect(_on_redraw)

func on_removed() -> void:
	_run.signals.redraw_finished.disconnect(_on_redraw)
	super.on_removed()

func _on_redraw(is_first: bool) -> void:
	if not is_first:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _run.get_current_stage().get_card_deck().draw(CardDeck.CardDrawReason.RELIC, true, true)
		)
