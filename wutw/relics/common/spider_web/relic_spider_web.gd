@tool
class_name Relic_SpiderWeb
extends Relic

@export var aspect: AspectType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	super.on_removed()

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	if aspect in card.card_type.aspects:
		_run.run_or_queue_action(func() -> void:
			var stage := _run.get_current_stage()
			if not Utils.ensure(stage != null):
				return
			var deck := stage.get_card_deck()
			for hand_card in deck.get_hand_cards():
				if hand_card.card_type.rarity == CardType.Rarity.NEGATIVE:
					triggered.emit()
					await deck.discard(hand_card, CardDeck.DiscardReason.ABILITY)
					break
		)

func get_description() -> String:
	return tr(default_description) % aspect.get_term_tag()
