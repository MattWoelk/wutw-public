@tool
class_name HauntingTrigger_DeckReshuffled
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('the <term_lower:draw_pile> is reshuffled')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('Deck Reshuffled')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.deck_reshuffled.connect(_on_deck_reshuffled)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.deck_reshuffled.disconnect(_on_deck_reshuffled)

func _on_deck_reshuffled() -> void:
	triggered.emit(null, null, null)
