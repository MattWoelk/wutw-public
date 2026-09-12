@tool
class_name Relic_ConchTrumpet
extends Relic

@export var added_card: CardType

var _triggered_this_stage := false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.inspiration_lost.connect(_on_inspiration_lost)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.inspiration_lost.disconnect(_on_inspiration_lost)
	super.on_removed()

func _on_stage_started() -> void:
	_triggered_this_stage = false

func _on_inspiration_lost(_amount: int, _reason: Run.InspirationChangeReason) -> void:
	_run.run_or_queue_action(func() -> void:
		if _run.get_current_stage() and not _triggered_this_stage:
			_triggered_this_stage = true
			triggered.emit()
			var deck := _run.get_current_stage().get_card_deck()
			await deck.add_card_to_hand(added_card, CardDeck.CardDrawReason.RELIC)
	)

func get_description() -> String:
	return tr(default_description) % added_card.get_term_tag()
