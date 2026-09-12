class_name StageGoal
extends RefCounted

var bonus_requirements: Dictionary[BonusType, int]

func get_num_requirements() -> int:
	return bonus_requirements.size()

func get_remaining_requirements(bonus_amounts: BonusAmounts) -> Dictionary[BonusType, int]:
	var result: Dictionary[BonusType, int] = {}
	for bonus_type in bonus_requirements:
		var req_amount := bonus_requirements[bonus_type]
		var left := req_amount - bonus_amounts.get_amount(bonus_type)
		if left > 0:
			result[bonus_type] = left
	return result

func is_satisfied_with(bonus_type: BonusType, bonus_amounts: BonusAmounts) -> bool:
	var req_amount := bonus_requirements.get(bonus_type, 0) as int
	return bonus_amounts.get_amount(bonus_type) >= req_amount

func get_excess(bonus_amounts: BonusAmounts) -> int:
	var total_excess := 0
	for bonus_type in bonus_amounts.get_bonus_types():
		var available := bonus_amounts.get_amount(bonus_type)
		var needed := bonus_requirements.get(bonus_type, 0) as int
		var excess := maxi(0, available - needed)
		total_excess += excess
	return total_excess

func encode() -> Dictionary[String, int]:
	var encoded: Dictionary[String, int] = {}
	for bonus_type in bonus_requirements:
		encoded[bonus_type.bonus_type_id] = bonus_requirements[bonus_type]
	return encoded

func decode(encoded_data: Dictionary) -> void:
	bonus_requirements.clear()
	for bonus_id: String in encoded_data:
		bonus_requirements[BonusType.get_bonus_type_by_id(bonus_id)] = encoded_data[bonus_id] as int
