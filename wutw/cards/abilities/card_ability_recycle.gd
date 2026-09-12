@tool
class_name CardAbility_Recycle
extends CardAbility

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	var result := tr('Recycle', 'ABILITY')
	if count > 1:
		result += ' %d' % count
	return result

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return tr('<term:draw> 1 random <term_lower:glyph> from the <term:discard_pile>, if available.')
	else:
		return tr('<term:draw> %d random <term_lower:glyph>s from the <term:discard_pile>, if available.') % count

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_recycle.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	var any_cards_drawn := [false]  # Array, so we can capture it.
	var error_shown := [false]  # Array, so we can capture it.
	for _i in range(count):
		stage.queue_action(func() -> void:
			if deck.get_discard_pile_cards():
				await deck.draw(CardDeck.CardDrawReason.ABILITY, true, true)
				any_cards_drawn[0] = true
			else:
				if not error_shown[0]:
					error_shown[0] = true
					if any_cards_drawn[0]:
						GlobalUI.show_error(tr('There are no more <term_lower:glyph>s in the <term_lower:discard_pile> to <term_lower:draw>.'))
					else:
						GlobalUI.show_error(tr('There are no <term_lower:glyph>s in the <term_lower:discard_pile> to <term_lower:draw>.'))
					await deck.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
		)

func estimate_power(card_type: CardType) -> int:
	if card_type.abilities.size() == 1 and count > 1:
		return 1000  # Can allow infinite loops!
	if card_type.abilities.size() > 1:
		var other_ability := card_type.abilities[1 if card_type.abilities[0] == self else 0]
		if other_ability.scales_when_looped() and other_ability.estimate_power(card_type) > 0:
			return 1000  # Can allow infinite loops!
	match count:
		1: return 15
		2: return 50
		3: return 100
		4: return 150
		_: return count * 30
