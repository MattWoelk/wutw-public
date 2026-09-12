@tool
class_name CardAbility_Reserve
extends CardAbility

@export var copies: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	return tr('Store', 'ABILITY') if copies == 1 else (tr('Store', 'ABILITY') + ' %d' % copies)

func get_ability_tooltip(_card: Card) -> String:
	if copies == 1:
		return tr('Place this <term_lower:glyph> on top of the <term_lower:draw_pile>.')
	else:
		return tr('Place %d copies of this <term_lower:glyph> on top of the <term_lower:draw_pile>.') % copies

func cast(card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	for _i in copies:
		stage.queue_action(func() -> void:
			await deck.add_card_to_draw_pile(card.card_type)
		)

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_reserve.tres')

func should_destroy_on_cast() -> bool:
	return true

func estimate_power(card_type: CardType) -> int:
	var aspect_power := card_type.estimate_aspect_power()
	var other_ability_power := 0
	for ability in card_type.abilities:
		if ability != self:
			other_ability_power += ability.estimate_power(card_type)
	var topped_power := maxi(aspect_power, other_ability_power)
	if topped_power > 15:  # Good cards are worth keeping.
		topped_power *= copies
	return roundi(topped_power * 0.6)

func scales_when_looped() -> bool:
	return false  # Arguable, but not strictly so.
