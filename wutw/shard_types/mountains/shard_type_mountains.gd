@tool
class_name ShardType_Mountains
extends ShardType

@export var mountain: SpotType
@export var canyon: SpotType
@export var volcano: SpotUpgrade
@export var ice_peak: SpotUpgrade
@export var cliff_dwellings: SpotUpgrade
@export var min_settlements: int = 6

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return run_data.settlement_states.size() / float(min_settlements)
		1:
			for settlement_state in run_data.settlement_states:
				if mountain not in settlement_state.spot_types and canyon not in settlement_state.spot_types:
					return -1
			return 0 if run_data.settlement_states.is_empty() else 1
		2:
			return 1 if get_upgrade_settlement(run_data, volcano) else 0
		3:
			return 1 if get_upgrade_settlement(run_data, ice_peak) else 0
		4:
			return 1 if get_upgrade_settlement(run_data, cliff_dwellings) else 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('At least %d <term_lower:settlement>s.') % min_settlements,
		tr('A <spot:%s> or <spot:%s> <term_lower:spot> in each <term_lower:settlement>.') % [mountain.spot_type_id, canyon.spot_type_id],
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade>.') % volcano.spot_upgrade_id,
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade>.') % ice_peak.spot_upgrade_id,
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade>.') % cliff_dwellings.spot_upgrade_id,
	]

func format_history_text(index: int, past_run: PastRun, text_override: String = '') -> String:
	var text := super.format_history_text(index, past_run, text_override)
	var volcano_town_name := get_upgrade_settlement(past_run.run_data, volcano).settlement_name.get_native_display_name()
	var ice_town_name := get_upgrade_settlement(past_run.run_data, ice_peak).settlement_name.get_native_display_name()
	var canyon_town_name := get_upgrade_settlement(past_run.run_data, cliff_dwellings).settlement_name.get_native_display_name()
	return _apply_replacements(text, {
		'$ice_town': '[b]' + ice_town_name + '[/b]',
		'$volcano_town': '[b]' + volcano_town_name + '[/b]',
		'$canyon_town': '[b]' + canyon_town_name + '[/b]',
	})

func get_upgrade_settlement(run_data: RunData, required_upgrade: SpotUpgrade) -> SettlementState:
	for settlement_state in run_data.settlement_states:
		for upgrades in settlement_state.activated_upgrades:
			if required_upgrade in upgrades:
				return settlement_state
	return null

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	config = config.duplicate(true)

	# Guarantee canyon.
	for stamp in config.stamp_configs:
		if stamp.comment == 'canyon':
			stamp.stamp_count_range.x = 1
			stamp.stamp_count_range.y += 1

	# More mountains.
	config.biome_config = config.biome_config.duplicate()
	config.biome_config.min_altitude_for_mountain = 0.8

	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [volcano, ice_peak, cliff_dwellings]
