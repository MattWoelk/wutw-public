@tool
class_name ShardType_Autocracy
extends ShardType

@export var event: Event_Stage
@export var var_name: String

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			if run_data.events_state.get_bool_or_default(event.event_id, var_name, false):
				return 1
			elif _has_finished_event(run_data, event):
				return -1
			else:
				return 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('Acquire the <term:relic.inheritance_scroll> <term_lower:relic> during the <spot:%s> <term_lower:event>: <event:%s>.') % [
			event.default_spot_upgrade.spot.spot_type_id, event.event_id]]

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [event.default_spot_upgrade]
