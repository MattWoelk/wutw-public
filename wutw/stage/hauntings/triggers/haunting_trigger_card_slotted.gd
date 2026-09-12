@tool
class_name HauntingTrigger_CardSlotted
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('a <term_lower:glyph> is <term_lower:slot_card>ted')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('<term:glyph> <term:slot_card>ted')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_slotted.connect(_on_card_slotted)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_slotted.disconnect(_on_card_slotted)

func _on_card_slotted(card: Card, aspect_slot: AspectSlot) -> void:
	triggered.emit(null, aspect_slot, card.card_type)
