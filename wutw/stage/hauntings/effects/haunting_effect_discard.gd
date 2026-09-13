@tool
class_name HauntingEffect_Discard
extends HauntingEffect

@export var aspect_type: AspectType

func get_description(_mode: HauntingTrigger.Mode) -> String:
	if aspect_type:
		return tr('<term_lower:discard> a random <term_lower:glyph> with %s') % aspect_type.get_term_tag(true)
	else:
		return tr('<term_lower:discard> a random <term_lower:glyph>')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	if aspect_type:
		return '<term:discard> [img width=1.5em height=1.5em]%s[/img]' % aspect_type.get_used_icon().resource_path
	else:
		return '<term:discard>'

func scales() -> bool:
	return false

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var card_deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		var card: Card
		if aspect_type:
			var options: Array[Card]
			for hand_card in card_deck.get_hand_cards():
				if aspect_type in hand_card.card_type.aspects:
					options.append(hand_card)
			if not options:
				return
			card = run.get_card_deck_random().pick(options)
		else:
			card = card_deck.get_random_from_hand()
		if card:  # Hand may be empty.
			await card_deck.discard(card, CardDeck.DiscardReason.HAUNTING)
	)
