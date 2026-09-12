@tool
class_name ShardType_SmallCommunity
extends ShardType

@export var min_settlements: int = 4

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.settlement_states.size() / float(min_settlements)
		1: return 1.0 if run_data.capital_location.x < 0 else 0.0
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d settlements.') % min_settlements,
			tr('No capital.')]
