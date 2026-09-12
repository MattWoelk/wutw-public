@tool
class_name HauntingTrigger_CardPlayed
extends HauntingTrigger

@export var required_aspect: AspectType

func get_description(_mode: HauntingTrigger.Mode) -> String:
	if required_aspect:
		return tr('a <term_lower:glyph> with %s <term_lower:aspect> is <term_lower:play_card>ed') % required_aspect.get_term_tag()
	else:
		return tr('a <term_lower:glyph> is <term_lower:play_card>ed')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	if required_aspect:
		return tr('%s <term:play_card>ed') % required_aspect.get_term_tag()
	else:
		return tr('<term:glyph> <term:play_card>ed')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_slotted.connect(_on_card_slotted)
	run.signals.card_cast_finished.connect(_on_card_cast)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.card_slotted.disconnect(_on_card_slotted)
	run.signals.card_cast_finished.disconnect(_on_card_cast)

func _on_card_slotted(card: Card, aspect_slot: AspectSlot) -> void:
	if required_aspect and required_aspect not in card.card_type.aspects:
		return
	triggered.emit(null, aspect_slot, card.card_type)

func _on_card_cast(card: Card) -> void:
	if required_aspect and required_aspect not in card.card_type.aspects:
		return
	triggered.emit(null, null, card.card_type)
