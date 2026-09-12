@tool
class_name ShardType_Hunger
extends ShardType

@export var food_bonus_type: BonusType
@export var max_food: int = 50
@export var min_settlements: int = 8

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.settlement_states.size() / float(min_settlements)
		1:
			var food_amount := run_data.bonus_amounts.get_amount(food_bonus_type)
			if food_amount > max_food:
				return 0
			else:
				return 2.0 - food_amount / float(max_food)
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d settlements.') % min_settlements,
			tr('No more than %d %s.') % [max_food, food_bonus_type.get_term_tag()]]
