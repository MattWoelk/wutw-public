class_name BonusAmounts
extends RefCounted

signal changed

var _amounts: Dictionary[BonusType, int] = {}

func add_amount(bonus_type: BonusType, amount: int) -> void:
	assert(bonus_type)
	if bonus_type in _amounts:
		_amounts[bonus_type] += amount
	else:
		_amounts[bonus_type] = amount
	changed.emit()

func add_all(other_amounts: BonusAmounts) -> void:
	for bonus_type in other_amounts.get_bonus_types():
		add_amount(bonus_type, other_amounts.get_amount(bonus_type))

func get_amount(bonus_type: BonusType) -> int:
	if bonus_type in _amounts:
		return _amounts[bonus_type]
	else:
		return 0

func clear() -> void:
	_amounts.clear()
	changed.emit()

func get_bonus_types() -> Array[BonusType]:
	return _amounts.keys()

func duplicate() -> BonusAmounts:
	var result := BonusAmounts.new()
	result.add_all(self)
	return result

func encode() -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for bonus_type in _amounts:
		result[bonus_type.bonus_type_id] = _amounts[bonus_type]
	return result

func decode(encoded_data: Dictionary) -> void:
	_amounts.clear()
	for bonus_id: String in encoded_data:
		_amounts[BonusType.get_bonus_type_by_id(bonus_id)] = encoded_data[bonus_id] as int
