@tool
class_name HauntingTrigger_RareCardPlayed
extends HauntingTrigger

@export var min_rarity: CardType.Rarity = CardType.Rarity.RARE

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return (tr('a <term_lower:glyph> of %s or higher rarity is <term_lower:play_card>ed')
			% CardType.get_rarity_name_static(min_rarity))

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('%s+ <term:play_card>ed') % CardType.get_rarity_name_static(min_rarity)

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_slotted.connect(_on_card_slotted)
	run.signals.card_cast_finished.connect(_on_card_cast)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_slotted.disconnect(_on_card_slotted)
	run.signals.card_cast_finished.disconnect(_on_card_cast)

func _on_card_slotted(card: Card, aspect_slot: AspectSlot) -> void:
	if card.card_type.rarity < min_rarity or card.card_type.rarity == CardType.Rarity.NEGATIVE:
		return
	triggered.emit(null, aspect_slot, card.card_type)

func _on_card_cast(card: Card) -> void:
	if card.card_type.rarity < min_rarity or card.card_type.rarity == CardType.Rarity.NEGATIVE:
		return
	triggered.emit(null, null, card.card_type)
