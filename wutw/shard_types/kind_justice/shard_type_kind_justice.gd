@tool
class_name ShardType_KindJustice
extends ShardType

@export var harmony: BonusType
@export var min_harmony_amount: int = 300
@export var safety: BonusType
@export var min_safety_amount: int = 200

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.bonus_amounts.get_amount(harmony) / float(min_harmony_amount)
		1: return run_data.bonus_amounts.get_amount(safety) / float(min_safety_amount)
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d %s.') % [min_harmony_amount, harmony.get_term_tag()],
			tr('At least %d %s.') % [min_safety_amount, safety.get_term_tag()]]
