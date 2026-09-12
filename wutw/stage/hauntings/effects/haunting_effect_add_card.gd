@tool
class_name HauntingEffect_AddCard
extends HauntingEffect

@export var card_type: CardType

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('add a %s <term_lower:glyph> to your <term_lower:hand>') % card_type.get_term_tag()

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('Get ') + card_type.get_term_tag()

func scales() -> bool:
	return false

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var card_deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		await card_deck.add_card_to_hand(card_type, CardDeck.CardDrawReason.HAUNTING)
	)
