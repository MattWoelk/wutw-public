class_name StageSatisfiability
extends Object

# This is overly complicated beause it used to be a hotspot.
# It could be simplified, but this is rarely touched code, so seems harmless...

static func get_max_spot_bonuses(run: Run, spot: SpotType, is_first_spot_copy: bool, filter: Array[BonusType] = [], ignore_limits: bool = false) -> Dictionary[BonusType, int]:
	var outcomes := _get_spot_gain_possibilities(run, spot, is_first_spot_copy, filter, ignore_limits)
	var max_bonuses: Dictionary[BonusType, int] = {}
	for outcome in outcomes.branch_outcomes:
		var outcome_dict := outcome.to_dict()
		for bonus_type in outcome_dict:
			max_bonuses[bonus_type] = max(max_bonuses.get(bonus_type, 0), outcome_dict[bonus_type])
	return max_bonuses

static func get_sorted_spot_bonuses(run: Run, spot: SpotType, is_first_spot_copy: bool, filter: Array[BonusType] = [], ignore_limits: bool = false) -> Array[BonusType]:
	var max_bonuses := get_max_spot_bonuses(run, spot, is_first_spot_copy, filter, ignore_limits)
	var bonus_types := max_bonuses.keys()
	bonus_types.sort_custom(func(a: BonusType, b: BonusType) -> bool:
		return max_bonuses[a] > max_bonuses[b]
	)
	return bonus_types

static func _get_spot_gain_possibilities(run: Run, spot: SpotType, is_first_spot_copy: bool, filter: Array[BonusType] = [], ignore_limits: bool = false) -> SpotGainPossibilties:
	var result := SpotGainPossibilties.new()

	var ensured_upgrades: Dictionary[SpotUpgrade, bool]

	for quest_instance in GlobalSaveGame.get_all_quest_instances():
		if quest_instance.is_active():
			for ensured in quest_instance.get_quest().get_ensured_upgrades():
				if ensured.spot == spot:
					ensured_upgrades[ensured] = true
	if GlobalSaveGame.get_pinned_shard_type():
		for ensured in GlobalSaveGame.get_pinned_shard_type().get_ensured_upgrades():
			if ensured.spot == spot:
				ensured_upgrades[ensured] = true

	var traverse := func(upgrade: SpotUpgrade, cumulative: Dictionary[BonusType, int], recurse: Callable) -> bool:
		if not ignore_limits and not upgrade.is_allowed(run, is_first_spot_copy):
			return false

		var new_cumulative: Dictionary[BonusType, int] = cumulative.duplicate()
		for bonus: BonusType in upgrade.granted_bonuses.keys():
			new_cumulative[bonus] = new_cumulative.get(bonus, 0) + upgrade.granted_bonuses[bonus]

		var any_children := false
		for child in upgrade.child_upgrades:
			any_children = recurse.call(child, new_cumulative, recurse) or any_children

		if not any_children:  # Leaf
			if upgrade not in ensured_upgrades:
				if filter and cumulative:  # Always allow first level, where cumulative is empty.
					var any_matched := false
					for bonus_type in filter:
						if upgrade.granted_bonuses.get(bonus_type, 0) > 0:
							any_matched = true
							break
					if not any_matched:
						return false
			result.branch_outcomes.append(SpotBranchOutcome.from_dict(new_cumulative))
		return true

	for upgrade in spot.upgrades:
		traverse.call(upgrade, {} as Dictionary[BonusType, int], traverse)

	return result

# Bonus Bitset Operations

static func _bonus_types_to_bitset(bonus_types: Array[BonusType]) -> int:
	var result: int = 0
	for bonus_type in bonus_types:
		result |= (1 << bonus_type.sort_order)
	return result

static func _bonus_bitset_to_types(bitset: int) -> Array[BonusType]:
	var result: Array[BonusType] = []
	for bonus_type in BonusType.get_all_types():
		if bitset & (1 << bonus_type.sort_order):
			result.append(bonus_type)
	return result

static func _get_subsets(bitset: int) -> Array[int]:
	var subsets: Array[int] = []
	var subset := bitset
	while subset:
		subset = (subset - 1) & bitset
		if subset:
			subsets.append(subset)
	return subsets

# Data Classes

class SpotBranchOutcome extends RefCounted:
	var bonus_bitset: int
	var amounts: PackedByteArray

	var _total: int = 0  # Calculated on demand and cached.

	func duplicate() -> SpotBranchOutcome:
		var result := SpotBranchOutcome.new()
		result.bonus_bitset = bonus_bitset
		result.amounts = amounts
		return result

	func add(other: SpotBranchOutcome) -> void:
		# This can be optimized.
		var dict := to_dict()
		var other_dict := other.to_dict()
		for bonus_type in other_dict:
			dict[bonus_type] = dict.get(bonus_type, 0) + other_dict[bonus_type]
		var sum := from_dict(dict)
		bonus_bitset = sum.bonus_bitset
		amounts = sum.amounts

	static func from_dict(dict: Dictionary[BonusType, int]) -> SpotBranchOutcome:
		var result := SpotBranchOutcome.new()
		result.bonus_bitset = StageSatisfiability._bonus_types_to_bitset(dict.keys())
		for bonus_type in StageSatisfiability._bonus_bitset_to_types(result.bonus_bitset):  # Canonical order.
			result.amounts.append(0)
			result.amounts.encode_s8(result.amounts.size() -1, dict[bonus_type])
		return result

	func to_dict() -> Dictionary[BonusType, int]:
		var result: Dictionary[BonusType, int] = {}
		var i := 0
		for bonus_type in StageSatisfiability._bonus_bitset_to_types(bonus_bitset):  # Canonical order.
			result[bonus_type] = amounts.decode_s8(i)
			i += 1
		return result

	func is_worse_or_equal(other: SpotBranchOutcome) -> bool:
		if bonus_bitset & other.bonus_bitset != bonus_bitset:
			return false  # This has bonuses not covered by other.
		# This can be optimized.
		var other_flat := other.to_flat_array()
		var i := 0
		for bonus_type in StageSatisfiability._bonus_bitset_to_types(bonus_bitset):  # Canonical order.
			var value := amounts.decode_s8(i)
			if value > other_flat[bonus_type.sort_order]:
				return false
			i += 1
		return true

	func to_flat_array() -> PackedInt32Array:
		var result := PackedInt32Array()
		result.resize(7)  # BonusType.get_all_types().size()
		var i := 0
		for bonus_type in StageSatisfiability._bonus_bitset_to_types(bonus_bitset):  # Canonical order.
			result[bonus_type.sort_order] = amounts.decode_s8(i)
			i += 1
		return result

	func total() -> int:
		if not _total:
			for i in range(amounts.size()):
				_total += amounts.decode_s8(i)
		return _total

class SpotGainPossibilties extends RefCounted:
	var branch_outcomes: Array[SpotBranchOutcome]
