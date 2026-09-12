@tool
class_name CardAbility_Discard
extends CardAbility

@export var count: int = 1
@export var only_negative := false

func get_ability_name(markedup: bool = false, _short: bool = false) -> String:
	var text: String
	if markedup:
		text = '<term:discard> %d' % count
	else:
		text = tr('Discard %d', 'ABILITY') % count
	if only_negative:
		text += ' ' + tr('Negative')
	return text

func get_ability_tooltip(_card: Card) -> String:
	if only_negative:
		if count == 1:
			return tr('<term:discard> 1 random <term_lower:negative_glyph>.')
		else:
			return tr('<term:discard> %d random <term_lower:negative_glyph>s.') % count
	else:
		if count == 1:
			return tr('<term:discard> 1 random <term_lower:glyph>.')
		else:
			return tr('<term:discard> %d random <term_lower:glyph>s.') % count

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_discard.tres')

func cast(_card: Card) -> void:
	assert(count > 0)

	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	var count_left: Array[int] = [count]
	var discard_action := func(recurse: Callable) -> void:
		var to_discard: Card
		if only_negative:
			for card in deck.get_hand_cards():
				if card.card_type.rarity == CardType.Rarity.NEGATIVE:
					to_discard = card
					break
		else:
			to_discard = deck.get_random_from_hand()
		if to_discard:
			await deck.discard(to_discard, CardDeck.DiscardReason.ABILITY)
		count_left[0] -= 1
		if count_left[0] > 0 and deck.get_hand_cards():
			stage.queue_action(recurse.bind(recurse))

	stage.queue_action(discard_action.bind(discard_action))

func estimate_power(_card_type: CardType) -> int:
	if only_negative:
		return 3 * count
	else:
		return max(-30, -6 * count)  # not -10 since you can dodge it, and 4+ cards is ~= all.

func scales_when_looped() -> bool:
	return false
