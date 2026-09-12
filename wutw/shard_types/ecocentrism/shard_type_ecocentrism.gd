@tool
class_name ShardType_Ecocentrism
extends ShardType

@export var min_settlements: int = 4
@export var sanctuary: SpotUpgrade
@export var extractive_developments: Array[SpotUpgrade]

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			if run_data.settlement_states.size() >= min_settlements:
				return 1
			else:
				return 0
		1:
			for settlement_state in run_data.settlement_states:
				for spot_upgrades: Array[SpotUpgrade] in settlement_state.activated_upgrades:
					if sanctuary in spot_upgrades:
						return 1
			return 0
		2:
			for settlement_state in run_data.settlement_states:
				for spot_upgrades: Array[SpotUpgrade] in settlement_state.activated_upgrades:
					for spot_upgrade in spot_upgrades:
						if spot_upgrade in extractive_developments:
							return -1
			return 1
		_: return -1

func describe_requirements() -> Array[String]:
	var extractive_names := ''
	for spot_upgrade in extractive_developments:
		extractive_names += tr('<spot_upgrade:%s> (<spot:%s>)\n') % [spot_upgrade.spot_upgrade_id, spot_upgrade.spot.spot_type_id]
	return [
		tr('At least %d settlements.') % min_settlements,
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade> in a <spot:%s>.') % [sanctuary.spot_upgrade_id, sanctuary.spot.spot_type_id],
		tr('No mining or woodcutting <term_lower:spot_upgrade>s:[ul]\n%s[/ul]') % extractive_names,
	]

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# More forest.
	config = config.duplicate()
	config.biome_config = config.biome_config.duplicate()
	config.biome_config.min_moisture_for_forest = 0.4
	config.biome_config.min_moisture_for_swamp = 0.75
	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [sanctuary]
