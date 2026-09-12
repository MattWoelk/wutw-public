@tool
class_name Relic_TwinnedSeed
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_added.connect(_on_card_added)

func on_removed() -> void:
	_run.signals.card_added.disconnect(_on_card_added)
	super.on_removed()

func _on_card_added(card_type: CardType) -> void:
	_run.run_or_queue_action(func() -> void:
		# WARNING: Don't emit event, else we'll get in an infinite loop.
		triggered.emit()
		_run.add_card_to_deck(card_type, true)
	)
