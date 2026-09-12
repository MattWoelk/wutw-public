@tool
class_name CardAbility_Spread
extends CardAbility

@export var aspect_type: AspectType

func get_ability_name(markedup: bool = false, short: bool = false) -> String:
	if aspect_type:
		if markedup:
			if short:
				return tr('Spread', 'ABILITY') + ' [img width=1.25em height=1.25em]%s[/img]' % aspect_type.get_used_icon().resource_path
			else:
				return tr('Spread', 'ABILITY') + ' %s' % aspect_type.get_term_tag()
		else:
			return tr('Spread', 'ABILITY') + ' %s' % aspect_type.name
	else:
		return tr('Mirror', 'ABILITY')

func get_ability_tooltip(_card: Card) -> String:
	if aspect_type:
		return tr('Duplicate a random <term_lower:glyph> in your <term_lower:hand> that has %s <term:aspect>.') % aspect_type.get_term_tag()
	else:
		return tr('Duplicate a random <term_lower:glyph> in your <term_lower:hand>.')

func get_term() -> Term:
	if aspect_type:
		return load('res://cards/abilities/terms/term_card_ability_spread.tres')
	else:
		return load('res://cards/abilities/terms/term_card_ability_mirror.tres')

func cast(_card: Card) -> void:
	var stage := Utils.get_active_run().get_current_stage()
	var deck := stage.get_card_deck()
	var pool: Array[CardType] = []
	for hand_card in deck.get_hand_cards():
		if not aspect_type or aspect_type in hand_card.card_type.aspects:
			pool.append(hand_card.card_type)
	if pool:
		stage.queue_action(func() -> void:
			await deck.add_card_to_hand(deck.get_random_state().pick(pool) as CardType, CardDeck.CardDrawReason.ABILITY)
		)
	else:
		stage.queue_action(func() -> void:
			if aspect_type:
				GlobalUI.show_error(tr('Your hand has no <term_lower:glyph>s with %s <term_lower:aspect>.') % aspect_type.get_term_tag(true))
			else:
				GlobalUI.show_error(tr('Your hand has no <term_lower:glyph>s in your <term_lower:hand>.'))
			await deck.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
		)

func estimate_power(card_type: CardType) -> int:
	if card_type.abilities.size() > 1:
		var other_ability := card_type.abilities[1 if card_type.abilities[0] == self else 0]
		if other_ability.scales_when_looped() and other_ability.estimate_power(card_type) > 0:
			return 1000  # Can allow infinite loops!
	return 14 + (0 if aspect_type in card_type.aspects else 4)  # Usually useless, but can get super strong endgame.
