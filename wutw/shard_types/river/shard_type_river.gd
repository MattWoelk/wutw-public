@tool
class_name ShardType_River
extends ShardType

@export var event: Event
@export var river_spot: SpotType

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			if run_data.settlement_states.is_empty():
				return 0
			elif _get_river_towns(run_data).size() >= ceili(run_data.settlement_states.size() / 2.0):
				return 1
			else:
				return 0
		1:
			if event.has_triggered(run_data):
				return 1
			else:
				return 0
		2: return 0.0 if run_data.capital_location.x < 0 else 1.0
		_: return -1

func format_history_text(index: int, past_run: PastRun, text_override: String = '') -> String:
	var text := super.format_history_text(index, past_run, text_override)
	return _apply_replacements(text, {
		'$river_town': '[b]' + _get_river_towns(past_run.run_data)[0].settlement_name.get_native_display_name() + '[/b]',
	})

func _get_river_towns(run_data: RunData) -> Array[SettlementState]:
	var result: Array[SettlementState]
	for settlement_state in run_data.settlement_states:
		if river_spot in settlement_state.spot_types:
			result.append(settlement_state)
	return result

func describe_requirements() -> Array[String]:
	return [
		tr('At least half of the settlements include a <spot:river> <term_lower:spot_upgrade>.'),
		tr('Complete the <spot:river> <term_lower:event>: <event:%s>.') % event.event_id,
		tr('An established <term_lower:capital>.'),
	]

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# Longer river.
	config = config.duplicate()
	config.river_config = config.river_config.duplicate()
	config.river_config.min_length = 8
	config.river_config.min_good_length = 15
	config.river_config.max_good_length = 25
	return config
