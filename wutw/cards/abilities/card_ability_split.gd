@tool
class_name CardAbility_Split
extends CardAbility

static var _basic_cards: Dictionary[AspectType, Array]  # Array[CardType]

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	return tr('Split', 'ABILITY')

func get_ability_tooltip(_card: Card) -> String:
	return tr('Add <term_lower:simple> <term_lower:glyph>s with each of this <term_lower:glyph>\'s <term_lower:aspect>s to your <term:hand>.')

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_split.tres')

func cast(card: Card) -> void:
	if not _basic_cards:
		for card_type in CardType.get_all_card_types_by_tier(CardType.Rarity.BASIC, CardType.Rarity.COMMON):
			if card_type.aspects.is_empty():
				continue
			Utils.ensure(card_type.aspects.size() == 1)
			if card_type.abilities.is_empty():
				var aspect := card_type.aspects[0]
				if aspect not in _basic_cards:
					_basic_cards[aspect] = []
				_basic_cards[aspect].append(card_type)

	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var deck := stage.get_card_deck()
	for aspect in card.card_type.aspects:
		stage.queue_action(func() -> void:
			var picked_card := deck.get_random_state().pick(_basic_cards[aspect]) as CardType
			await deck.add_card_to_hand(picked_card, CardDeck.CardDrawReason.ABILITY, false)
		)

func estimate_power(card_type: CardType) -> int:
	return card_type.aspects.size() * 10
