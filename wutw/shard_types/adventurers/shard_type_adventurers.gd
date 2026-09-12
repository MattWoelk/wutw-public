@tool
class_name ShardType_Adventurers
extends ShardType

@export var adventure_bonus: BonusType
@export var min_adventure: int = 10
@export var guild: SpotUpgrade

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			if run_data.settlement_states.is_empty():
				return 0
			var total := 0.0
			for settlement_state in run_data.settlement_states:
				var adventure := settlement_state.bonus_amounts.get_amount(adventure_bonus)
				if adventure < min_adventure:
					return -1 if settlement_state.settlement_name else 0  # Failed if settlement already finished.
				total += adventure / float(min_adventure)
			return minf(2.0, total / run_data.settlement_states.size())
		1:
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if guild in upgrades:
						return 1
			return 0
		2: return 0.0 if run_data.capital_location.x < 0 else 1.0
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %s %s in each settlement.') % [min_adventure, adventure_bonus.get_term_tag()],
			tr('An <spot_upgrade:%s> <term_lower:spot_upgrade> in a <spot:%s>.') % [guild.spot_upgrade_id, guild.spot.spot_type_id],
			tr('An established <term_lower:capital>.')]

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [guild]
