@tool
class_name CardAbility_AddCard
extends CardAbility

@export var card_type: CardType
@export var count: int = 1

func get_ability_name(markedup: bool = false, _short: bool = false) -> String:
	var text := tr('Conjure', 'ABILITY') + ' '
	if count == 1:
		text += card_type.symbol
	else:
		text += '%d %s' % [count, card_type.symbol]
	if markedup:
		text += '<related_term:%s>' % card_type.get_term_id()
	return text

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return (tr('Add one <related_term:%s>%s <term_lower:glyph> to your <term:hand>.') %
				[card_type.get_term_id(), card_type.get_term_tag()])
	else:
		return (tr('Add %d copies of the <related_term:%s>%s <term_lower:glyph> to your <term:hand>.') %
				[count, card_type.get_term_id(), card_type.get_term_tag()])

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_add_card.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	for _i in count:
		stage.queue_action(func() -> void:
			await deck.add_card_to_hand(card_type, CardDeck.CardDrawReason.ABILITY)
		)

func estimate_power(this_card_type: CardType) -> int:
	if not card_type:
		return 0
	if card_type.rarity == CardType.Rarity.NEGATIVE:
		return -5
	var merged_aspects: Array[AspectType]
	merged_aspects.append_array(this_card_type.aspects)
	for aspect in card_type.aspects:
		if aspect not in merged_aspects:
			merged_aspects.append(aspect)
	var added_aspect_power := CardType.estimate_aspect_list_power(merged_aspects) - this_card_type.estimate_aspect_power()
	var result := added_aspect_power + card_type.estimate_ability_power() * count
	if card_type.rarity == CardType.Rarity.NEGATIVE:
		result = min(result, -1)
	return result

func get_search_text() -> String:
	return ' '.join([tr('Conjure'), card_type.symbol, tr(card_type.card_name), str(count)])
