@tool
class_name ShardType_Religion
extends ShardType

@export var min_settlements: int = 8
@export var religious_buildings: Array[SpotUpgrade]

func score_requirement(run_data: RunData, index: int) -> float:
	match index:
		0: return min(1.5, run_data.settlement_states.size() / float(min_settlements))
		1:
			if run_data.settlement_states.is_empty():
				return 0
			for settlement_state in run_data.settlement_states:
				var any_matched := false
				for upgrades in settlement_state.activated_upgrades:
					for upgrade: SpotUpgrade in upgrades:
						if upgrade in religious_buildings:
							any_matched = true
							break
				if not any_matched:
					return -1 if settlement_state.settlement_name else 0
			return 1
		_: return -1

func describe_requirements() -> Array[String]:
	var building_names := ''
	for spot_upgrade in religious_buildings:
		building_names += tr('<spot_upgrade:%s> (<spot:%s>)\n') % [
			spot_upgrade.spot_upgrade_id, spot_upgrade.spot.spot_type_id]
	return [
		tr('At least %d settlements.') % min_settlements,
		tr('A shrine or temple <term_lower:spot_upgrade> in each settlement. One of:[ul]\n%s[/ul]') % building_names,
	]

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return religious_buildings
