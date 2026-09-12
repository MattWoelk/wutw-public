@tool
class_name ShardType_SeasonalMigration
extends ShardType

@export var dry_sites: Array[SpotType]
@export var wet_sites: Array[SpotType]
@export var min_settlements: int = 3

func score_requirement(run_data: RunData, index: int) -> float:
	var stats := _collect_stats(run_data)
	match index:
		0: return stats[0] / float(min_settlements)
		1: return stats[1] / float(min_settlements)
		2: return stats[2] / float(run_data.settlement_states.size()) if stats[2] > 0 else 0.0
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('At least %d settlements in a %s.') % [min_settlements, _get_site_names(dry_sites)],
			tr('At least %d different settlements in a %s.') % [min_settlements, _get_site_names(wet_sites)],
			tr('All settlements <term_lower:connect_settlement>ed to the <term_lower:capital>.')]

func format_history_text(index: int, past_run: PastRun, text_override: String = '') -> String:
	var text := super.format_history_text(index, past_run, text_override)
	var dry_town_name: String
	var wet_town_name: String
	for settlement_state in past_run.run_data.settlement_states:
		for spot_type in settlement_state.spot_types:
			if spot_type in dry_sites:
				dry_town_name = settlement_state.settlement_name.get_native_display_name()
			elif spot_type in wet_sites:
				wet_town_name = settlement_state.settlement_name.get_native_display_name()
	if not Utils.ensure(not dry_town_name.is_empty()) or not Utils.ensure(not wet_town_name.is_empty()):
		return text
	return _apply_replacements(text, {
		'$dry_town': '[b]' + dry_town_name + '[/b]',
		'$wet_town': '[b]' + wet_town_name + '[/b]',
	})

func _collect_stats(run_data: RunData) -> Array[int]:
	var num_dry := 0
	var num_wet := 0
	var num_connected := 0
	for settlement_state in run_data.settlement_states:
		for spot_type in settlement_state.spot_types:
			if spot_type in dry_sites:
				num_dry += 1
				break
			elif spot_type in wet_sites:
				num_wet += 1
				break
		if settlement_state.is_settlement_connected:
			num_connected += 1
	return [num_dry, num_wet, num_connected]

func _get_site_names(spot_types: Array[SpotType]) -> String:
	var names: Array[String]
	names.assign(spot_types.map(func(s: SpotType) -> String:
		return '<spot:' + s.spot_type_id + '>'
	))
	return Utils.format_conjunction(names, true)

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# Less brushland and steppe.
	config = config.duplicate()
	config.biome_config = config.biome_config.duplicate()
	config.biome_config.min_moisture_for_forest = 0.5
	config.biome_config.max_moisture_for_steppe = 0.5
	config.biome_config.max_temperature_for_brushland = 0.5
	config.biome_config.max_moisture_for_dry_biome = 0.5
	return config
