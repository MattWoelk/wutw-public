@tool
class_name ShardType_Lazy
extends ShardType

@export var productivity: BonusType
@export var max_positivity: int = -50
@export var grove: SpotUpgrade
@export var min_settlements: int = 8
@export var min_glades: int = 3

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return min(0, run_data.bonus_amounts.get_amount(productivity)) / max_positivity
		1: return run_data.settlement_states.size() / float(min_settlements)
		2:
			var num_glades := 0
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if grove in upgrades:
						num_glades += 1
			return num_glades / float(min_glades)
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('At most [color=#880000]%d %s[/color].') % [max_positivity, productivity.get_term_tag()],
		tr('At least %d <term_lower:settlement>s.') % min_settlements,
		tr('At least %d <spot_upgrade:%s> <term_lower:spot_upgrade>s in <spot:%s>s.') % [min_glades, grove.spot_upgrade_id, grove.spot.spot_type_id],
	]

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# More forest.
	config = config.duplicate()
	config.biome_config.min_moisture_for_forest = 0.5
	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [grove]
