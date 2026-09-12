@tool
class_name HauntingTrigger_CardCast
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('a non-<term_lower:negative_glyph> is <term_lower:cast_card>')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('<term:glyph> <term:cast_card>')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_cast_finished.connect(_on_card_cast)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_cast_finished.disconnect(_on_card_cast)

func _on_card_cast(card: Card) -> void:
	if card.card_type.rarity != CardType.Rarity.NEGATIVE:
		triggered.emit(null, null, card.card_type)
