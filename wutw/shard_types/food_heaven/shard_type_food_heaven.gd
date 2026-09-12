@tool
class_name ShardType_FoodHeaven
extends ShardType

@export var food_bonus_type: BonusType
@export var min_food: int = 200

func score_requirement(run_data: RunData, index: int) -> float:
	var food_amount := run_data.bonus_amounts.get_amount(food_bonus_type)
	match index:
		0: return food_amount / float(min_food)
		1:
			for bonus in run_data.bonus_amounts.get_bonus_types():
				if food_amount < run_data.bonus_amounts.get_amount(bonus):
					return 0
			return 1
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d %s.') % [min_food, food_bonus_type.get_term_tag()],
			tr('%s higher than all other yields.') % food_bonus_type.get_term_tag()]
