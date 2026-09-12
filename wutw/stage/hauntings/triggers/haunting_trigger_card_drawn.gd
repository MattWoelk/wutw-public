@tool
class_name HauntingTrigger_CardDrawn
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('a <term_lower:glyph> is <term_lower:draw>n')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('<term:glyph> <term:draw>n')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_drawn.connect(_on_card_drawn)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_drawn.disconnect(_on_card_drawn)

func _on_card_drawn(card: Card, _reason: CardDeck.CardDrawReason, from_discards: bool) -> void:
	if not from_discards:
		triggered.emit(null, null, card.card_type)
