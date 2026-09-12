@tool
class_name HauntingTrigger_Start
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('the <term_lower:stage> starts')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('Stage Start')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	triggered.emit(null, null, null)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	pass
