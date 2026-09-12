@tool
class_name ShardType_Lightning
extends ShardType

@export var citadel: SpotUpgrade
@export var camp: SpotUpgrade
@export var min_camps: int = 3

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			var num_camps := 0
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if camp in upgrades:
						num_camps += 1
			return num_camps / float(min_camps)
		1:
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if citadel in upgrades:
						return 1
			return 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('At least %d <spot_upgrade:%s> <term_lower:spot_upgrade>s in <spot:%s>s.') % [min_camps, camp.spot_upgrade_id, camp.spot.spot_type_id],
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade> in a <spot:%s>.') % [citadel.spot_upgrade_id, citadel.spot.spot_type_id],
	]

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# More wasteland.
	config = config.duplicate()
	config.biome_config = config.biome_config.duplicate()
	config.biome_config.max_moisture_for_dry_biome = 0.55
	config.biome_config.min_temperature_for_desert = 0.55
	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [camp, citadel]
