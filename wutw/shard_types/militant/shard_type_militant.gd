@tool
class_name ShardType_Militant
extends ShardType

@export var safety: BonusType
@export var min_safety: int = 150
@export var harmony: BonusType
@export var max_harmony: int = 50
@export var min_unconnected: int = 6
@export var watchpost: SpotUpgrade
@export var min_watchposts: int = 2

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.bonus_amounts.get_amount(safety) / float(min_safety)
		1:
			var harmony_amount := run_data.bonus_amounts.get_amount(harmony)
			if harmony_amount > max_harmony:
				return 0
			else:
				return 2.0 - harmony_amount / float(max_harmony)
		2:
			var num_unconnected := 0
			for settlement_state in run_data.settlement_states:
				if not settlement_state.is_settlement_connected:
					num_unconnected += 1
			return num_unconnected / float(min_unconnected)
		3:
			var num_watchposts := 0
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if watchpost in upgrades:
						num_watchposts += 1
			return num_watchposts / float(min_watchposts)
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d %s.') % [min_safety, safety.get_term_tag()],
			tr('No more than %d %s.') % [max_harmony, harmony.get_term_tag()],
			tr('At least %d settlements not <term_lower:connect_settlement>ed to the <term_lower:capital>.') % min_unconnected,
			tr('At least %d <spot_upgrade:%s> <term_lower:spot_upgrade>s in <spot:%s>s.') % [
				min_watchposts, watchpost.spot_upgrade_id, watchpost.spot.spot_type_id]]

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [watchpost]
