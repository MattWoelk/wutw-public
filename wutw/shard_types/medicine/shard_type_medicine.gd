@tool
class_name ShardType_Medicine
extends ShardType

@export var event: Event_Stage
@export var var_name: String
@export var relic: Relic  # For description only.
@export var knowledge: BonusType
@export var min_knowledge: int = 150
@export var hospital: SpotUpgrade

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0:
			if run_data.events_state.get_bool_or_default(event.event_id, var_name, false):
				return 1
			elif _has_finished_event(run_data, event):
				return -1
			else:
				return 0
		1: return run_data.bonus_amounts.get_amount(knowledge) / float(min_knowledge)
		2:
			for settlement_state in run_data.settlement_states:
				for upgrades in settlement_state.activated_upgrades:
					if hospital in upgrades:
						return 1
			return 0
		_: return -1

func describe_requirements() -> Array[String]:
	return [
		tr('Acquire the %s <term_lower:relic> during the <spot:%s> <term_lower:event>: <event:%s>.') % [
			relic.get_relic_name(), event.default_spot_upgrade.spot.spot_type_id, event.event_id],
		tr('At least %d %s.') % [min_knowledge, knowledge.get_term_tag()],
		tr('A <spot_upgrade:%s> <term_lower:spot_upgrade> in a <spot:%s>.') % [
			hospital.spot_upgrade_id, hospital.spot.spot_type_id],
	]

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return [event.default_spot_upgrade, hospital]
