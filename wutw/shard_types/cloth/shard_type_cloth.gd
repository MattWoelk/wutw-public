@tool
class_name ShardType_Cloth
extends ShardType

@export var cloth_upgrades: Array[SpotUpgrade]

func score_requirement(run_data: RunData, index: int) -> float:
	if index < cloth_upgrades.size():
		var cloth_upgrade := cloth_upgrades[index]
		for settlement_state in run_data.settlement_states:
			for upgrades in settlement_state.activated_upgrades:
				if cloth_upgrade in upgrades:
					return 1
		return 0
	else:
		return -1

func describe_requirements() -> Array[String]:
	var result: Array[String]
	for upgrade in cloth_upgrades:
		result.append(tr('A <spot_upgrade:%s> <term_lower:spot_upgrade> in the <spot:%s>.') % [upgrade.spot_upgrade_id, upgrade.spot.spot_type_id])
	return result

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	config = config.duplicate(true)

	# More lakes.
	for stamp in config.stamp_configs:
		if stamp.comment == 'lake':
			stamp.stamp_count_range = Vector2(2, 5)

	# More brushland.
	config.biome_config.max_moisture_for_brushland = 0.5
	config.biome_config.max_temperature_for_brushland = 0.7

	# Longer river.
	config.river_config.min_length = 8
	config.river_config.min_good_length = 15
	config.river_config.max_good_length = 25

	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return cloth_upgrades
