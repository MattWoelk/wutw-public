@tool
class_name HauntingTrigger_End
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('the <term_lower:stage> ends')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('<term:stage> End')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	pass

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	triggered.emit(null, null, null)
