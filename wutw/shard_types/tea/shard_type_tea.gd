@tool
class_name ShardType_Tea
extends ShardType

@export var tea_start_event: Event_Stage
@export var tea_simplicity_event: Event_Stage

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			if run_data.events_state.get_bool_or_default(tea_start_event.event_id, 'card', false):
				return 1
			elif _has_finished_event(run_data, tea_start_event):
				return -1
			else:
				return 0
		1:
			if tea_simplicity_event.has_triggered(run_data):
				return 1
			else:
				return 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('Acquire the <term:card.tea> <term_lower:glyph> during the <spot:%s> <term_lower:event>: <event:%s>.') % [
			tea_start_event.default_spot_upgrade.spot.spot_type_id, tea_start_event.event_id],
		tr('Complete the <spot:%s> <term_lower:event>: <event:%s>.') % [
			tea_simplicity_event.default_spot_upgrade.spot.spot_type_id, tea_simplicity_event.event_id],
	]

func format_history_text(index: int, past_run: PastRun, text_override: String = '') -> String:
	var text := super.format_history_text(index, past_run, text_override)
	var first_stage_index := past_run.run_data.events_state.get_int_or_default(tea_start_event.event_id, Event.TRIGGERED_STAGE_INDEX_VAR, -1)
	var second_stage_index := past_run.run_data.events_state.get_int_or_default(tea_simplicity_event.event_id, Event.TRIGGERED_STAGE_INDEX_VAR, -1)
	if not Utils.ensure(first_stage_index > -1) or not Utils.ensure(second_stage_index > first_stage_index):
		return text
	return _apply_replacements(text, {
		'$teatown1': '[b]' + past_run.get_town_name(first_stage_index).get_native_display_name() + '[/b]',
		'$teatown2': '[b]' + past_run.get_town_name(second_stage_index).get_native_display_name() + '[/b]',
	})

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# More town squares.
	config = config.duplicate(true)
	for stamp in config.stamp_configs:
		if stamp.comment == 'hills':
			stamp.stamp_count_range.x += 1
	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [tea_start_event.default_spot_upgrade, tea_simplicity_event.default_spot_upgrade]
