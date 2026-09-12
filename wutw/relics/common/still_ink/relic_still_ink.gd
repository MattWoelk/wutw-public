@tool
class_name Relic_StillInk
extends Relic

@export var drawn_cards: int = 1

# Not saved because it's only used within a single stage.
var _has_cast_ability: bool

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_cast_finished.connect(_on_card_cast)
	_run.signals.redraw_finished.connect(_on_redraw_finished)
	_has_cast_ability = false

func on_removed() -> void:
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	super.on_removed()

func _on_card_cast(_card: Card) -> void:
	_has_cast_ability = true
	_state = State.PASSIVE

func _on_redraw_finished(_is_first: bool) -> void:
	if _state == State.ACTIVE and not _is_first:
		var deck := _run.get_current_stage().get_card_deck()
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await deck.draw(CardDeck.CardDrawReason.RELIC, true)
		)
	_state = State.ACTIVE
	_has_cast_ability = false

func get_description() -> String:
	return tr(default_description) % drawn_cards
