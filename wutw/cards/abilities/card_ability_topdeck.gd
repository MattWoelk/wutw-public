@tool
class_name CardAbility_Topdeck
extends CardAbility

@export var card_type: CardType
@export var count: int = 1

func get_ability_name(markedup: bool = false, _short: bool = false) -> String:
	var text := tr('Top', 'ABILITY')
	if count == 1:
		text += ' ' + card_type.symbol
	else:
		text += ' %d %s' % [count, card_type.symbol]
	if markedup:
		text += '<related_term:%s>' % card_type.get_term_id()
	return text

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return (tr('Add one <related_term:%s>%s <term_lower:glyph> to the top of the <term_lower:draw_pile>.') %
				[card_type.get_term_id(), card_type.get_term_tag()])
	else:
		return (tr('Add %d copies of the <related_term:%s>%s <term_lower:glyph> to the top of the <term_lower:draw_pile>.') %
				[count, card_type.get_term_id(), card_type.get_term_tag()])

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_topdeck.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	for _i in count:
		stage.queue_action(func() -> void:
			await deck.add_card_to_draw_pile(card_type)
		)

func estimate_power(_card_type: CardType) -> int:
	if not card_type:
		return 0
	# This is really situational...
	var topped_power := card_type.estimate_power()
	if topped_power > 15:  # Good cards are worth keeping.
		topped_power *= count
	if card_type.rarity == CardType.Rarity.NEGATIVE:
		topped_power = min(topped_power, -1)
	return roundi(topped_power * 0.6)

func scales_when_looped() -> bool:
	return false  # Arguable, but not strictly so.

func get_search_text() -> String:
	return ' '.join([tr('Top', 'ABILITY'), card_type.symbol, card_type.card_name, str(count)])
