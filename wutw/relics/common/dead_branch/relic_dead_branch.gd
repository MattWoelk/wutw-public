@tool
class_name Relic_DeadBranch
extends Relic

@export var aspect: AspectType
@export var added_card: CardType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.discard_finished.connect(_on_discard_finished)

func on_removed() -> void:
	_run.signals.discard_finished.disconnect(_on_discard_finished)
	super.on_removed()

func _on_discard_finished(card: Card, _reason: CardDeck.DiscardReason) -> void:
	if aspect in card.card_type.aspects:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			var deck := _run.get_current_stage().get_card_deck()
			await deck.add_card_to_draw_pile(added_card, false)
		)

func get_description() -> String:
	return tr(default_description) % [aspect.get_term_tag(), added_card.get_term_tag()]
