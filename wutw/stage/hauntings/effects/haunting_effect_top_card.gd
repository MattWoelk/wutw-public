@tool
class_name HauntingEffect_TopCard
extends HauntingEffect

@export var card_type: CardType

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('add a %s <term_lower:glyph> to the top of your <term_lower:draw_pile>') % card_type.get_term_tag()

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('Top ') + card_type.get_term_tag()

func scales() -> bool:
	return false

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var card_deck := stage.get_card_deck()
	stage.queue_action(func() -> void:
		await card_deck.add_card_to_draw_pile(card_type)
	)
