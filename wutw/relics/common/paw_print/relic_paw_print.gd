@tool
class_name Relic_PawPrint
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	super.on_removed()

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	if CardType.Tag.THEME_ANIMAL in card.card_type.tags:
		_run.run_or_queue_action(func() -> void:
			var stage := _run.get_current_stage()
			var deck := stage.get_card_deck()

			var options: Array[CardType]
			for card_type in CardType.get_all_card_types_by_tier(CardType.Rarity.BASIC, CardType.Rarity.COMMON):
				if card_type.aspects.is_empty():
					continue
				Utils.ensure(card_type.aspects.size() == 1)
				if card_type.abilities.is_empty() and card_type.aspects[0] in card.card_type.aspects:
					options.append(card_type)
			if not Utils.ensure(not options.is_empty()):
				options = CardType.get_all_card_types_by_tier(CardType.Rarity.BASIC, CardType.Rarity.COMMON)
			var added_card_type := deck.get_random_state().pick(options) as CardType

			triggered.emit()
			await deck.add_card_to_hand(added_card_type, CardDeck.CardDrawReason.RELIC)
		)
