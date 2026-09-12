@tool
class_name HauntingTrigger_SlotFilled
extends HauntingTrigger

@export var any_spot: bool = true

func get_description(mode: HauntingTrigger.Mode) -> String:
	if any_spot:
		return tr('any <term_lower:aspect_slot> is <term_lower:fill>ed')
	else:
		match mode:
			HauntingTrigger.Mode.SPOT:
				return tr('an <term_lower:aspect_slot> in this <term_lower:spot> is <term_lower:fill>ed')
			HauntingTrigger.Mode.HARMONIZATION:
				return tr('an <term_lower:aspect_slot> in this <term_lower:settlement> is <term_lower:fill>ed')
			HauntingTrigger.Mode.UNIVERSAL:
				return tr('an <term_lower:aspect_slot> in the associated <term_lower:spot> (during <term_lower:foray>s) or <term_lower:settlement> (during <term_lower:harmonization>) is <term_lower:fill>ed')
			_:
				Utils.ensure(false)
				return ''

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	if any_spot:
		return tr('Slot Filled')
	else:
		return tr('Slot Filled Here')

func setup(spot: Spot, settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.aspect_slot_filled.connect(_on_slot_filled.bind(spot, settlement))

func cleanup(spot: Spot, settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.aspect_slot_filled.disconnect(_on_slot_filled.bind(spot, settlement))

func _on_slot_filled(aspect_slot: AspectSlot, this_spot: Spot, this_settlement: Settlement) -> void:
	var matches: bool
	if any_spot:
		matches = true
	elif this_spot and aspect_slot in this_spot.get_all_aspect_slots():
		matches = true
	elif this_settlement and aspect_slot in this_settlement.get_aspect_slots():
		matches = true
	if matches:
		triggered.emit(null, aspect_slot, null)
