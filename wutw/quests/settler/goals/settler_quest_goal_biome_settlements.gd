class_name SettlerQuestGoal_BiomeSettlements
extends SettlerQuestGoal

@export var num_settlements: int = 2
@export var spot_type: SpotType

func start_listening(run: Run) -> void:
	run.signals.foray_finished.connect(_on_stage_finished)

func stop_listening(run: Run) -> void:
	run.signals.foray_finished.disconnect(_on_stage_finished)

func _on_stage_finished(settlement_state: SettlementState) -> void:
	var num_matching := 0
	if spot_type in settlement_state.spot_types:
		num_matching += 1
	for state in Utils.get_active_run().get_settlement_states():
		if spot_type in state.spot_types:
			num_matching += 1
	if num_matching >= num_settlements:
		achieved.emit()

func describe() -> String:
	assert(num_settlements > 0)
	return tr_n(
		'Establish at least %d <term_lower:settlement> with a <spot:%s> <term_lower:spot>.',
		'Establish at least %d <term_lower:settlement>s with a <spot:%s> <term_lower:spot>.',
		num_settlements) % [num_settlements, spot_type.spot_type_id]
