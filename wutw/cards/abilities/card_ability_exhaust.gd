@tool
class_name CardAbility_Exhaust
extends CardAbility

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	return tr('Fade Away', 'ABILITY')

func get_ability_tooltip(_card: Card) -> String:
	return tr('Remove [b]all copies of[/b] this <term_lower:glyph> for the rest of the <term_lower:stage>.')

func cast(card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	stage.queue_action(func() -> void:
		var deck := stage.get_card_deck()
		for other_card in deck.get_hand_cards([card]):
			if other_card.card_type == card.card_type:
				await deck.discard(other_card, CardDeck.DiscardReason.ABILITY, true)
		while true:
			if not deck.erase_card(card.card_type):
				break
		await stage.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
	)

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_exhaust.tres')

func should_destroy_on_cast() -> bool:
	return true

func estimate_power(_card_type: CardType) -> int:
	return -20

func scales_when_looped() -> bool:
	return false
