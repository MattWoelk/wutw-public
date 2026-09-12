@tool
class_name ShardType_MainQuest_AvatarHome
extends ShardType

@export var school: SpotUpgrade
@export var philosophy_corner: SpotUpgrade
@export var monasteries: Array[SpotUpgrade]

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return 1 if _find_avatar_home(run_data) else 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('All of the following <term_lower:spot_upgrade>s [b]in the same settlement[/b]:[ul]<spot_upgrade:%s>\n<spot_upgrade:%s>\nAny Monastery[/ul]') %
			[school.spot_upgrade_id, philosophy_corner.spot_upgrade_id]]

func format_history_text(index: int, past_run: PastRun, text_override: String = '') -> String:
	var text := super.format_history_text(index, past_run, text_override)
	return _apply_replacements(text, {
		'$avatar_town': '[b]' + _find_avatar_home(past_run.run_data).settlement_name.get_native_display_name() + '[/b]',
	})

func _find_avatar_home(run_data: RunData) -> SettlementState:
	if run_data.settlement_states.is_empty():
		return null
	for settlement_state in run_data.settlement_states:
		var all_upgrades: Array[SpotUpgrade]
		for upgrades in settlement_state.activated_upgrades:
			all_upgrades.append_array(upgrades)
		if school not in all_upgrades:
			continue
		if philosophy_corner not in all_upgrades:
			continue
		for monastery in monasteries:
			if monastery in all_upgrades:
				return settlement_state
	return null
