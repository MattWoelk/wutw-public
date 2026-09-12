@tool
class_name CardAbility_Adapt
extends CardAbility

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	if count:
		return tr('Adapt %d', 'ABILITY') % count
	else:
		return tr('Adapt', 'ABILITY')

func get_ability_tooltip(card: Card) -> String:
	var result := tr('Add %s with a random <term_lower:aspect> not already in your <term_lower:hand>.')
	if count == 1:
		result = result % tr('a <term_lower:simple> <term_lower:glyph>')
	else:
		result = result % (tr('%d <term_lower:simple> <term_lower:glyph>s') % count)
	var deck := Utils.get_typed_ancestor(card, CardDeck) as CardDeck
	if deck:
		var unowned_aspects := _get_unowned_aspects(deck, card)
		if unowned_aspects.is_empty():
			result += tr(' You currently have all <term_lower:aspect>s in your <term_lower:hand>.')
		else:
			result += tr(' Current possibilities:')
			for aspect in unowned_aspects:
				result += ' [img width=1.25em height=1.25em]%s[/img]' % aspect.get_used_icon().resource_path
	return result

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_adapt.tres')

func cast(card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		var unowned_aspects := _get_unowned_aspects(deck, card)
		if unowned_aspects.is_empty():
			GlobalUI.show_error(tr('Your hand already contains all <term_lower:aspect>s.'))
			return  # Have all aspects.

		for _i in count:
			var options: Array[CardType]
			for card_type in CardType.get_all_card_types_by_tier(CardType.Rarity.BASIC, CardType.Rarity.COMMON):
				if card_type.aspects.is_empty():
					continue
				Utils.ensure(card_type.aspects.size() == 1)
				if card_type.abilities.is_empty() and card_type.aspects[0] in unowned_aspects:
					options.append(card_type)
			if not Utils.ensure(not options.is_empty()):
				options = CardType.get_all_card_types_by_tier(CardType.Rarity.BASIC, CardType.Rarity.COMMON)

			var selected := deck.get_random_state().pick(options) as CardType
			await deck.add_card_to_hand(selected as CardType, CardDeck.CardDrawReason.ABILITY, false)
			# Prioritize adding different aspects, but allow fallback.
			if unowned_aspects.size() > 1:
				unowned_aspects.erase(selected.aspects[0])
	)

func estimate_power(_card_type: CardType) -> int:
	return 16 * min(3, count)  # Beyond 3 is rarely useful.

func _get_unowned_aspects(deck: CardDeck, card: Card) -> Array[AspectType]:
	var owned_aspects: Dictionary[AspectType, bool]
	for hand_card: Card in deck.get_hand_cards() + [card]:
		for aspect in hand_card.card_type.aspects:
			owned_aspects[aspect] = true

	var unowned_aspects := AspectType.get_all_types()
	for aspect in owned_aspects:
		unowned_aspects.erase(aspect)
	return unowned_aspects
