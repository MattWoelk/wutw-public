@tool
class_name Relic_ScallopShell
extends Relic

@export var required_spot_type: SpotType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_finished.connect(_on_foray_finished)
	for settlement in run.get_settlements():
		if required_spot_type in settlement.state.spot_types:
			for bonus_type in BonusType.get_all_types():
				settlement.satisfy_lack(bonus_type)

func on_removed() -> void:
	_run.signals.foray_finished.disconnect(_on_foray_finished)
	super.on_removed()

func _on_foray_finished(settlement_state: SettlementState) -> void:
	if required_spot_type in settlement_state.spot_types:
		for settlement in _run.get_settlements():
			if settlement_state == settlement.state:
				for bonus_type in BonusType.get_all_types():
					settlement.satisfy_lack(bonus_type)
		triggered.emit()

func get_description() -> String:
	return tr(default_description) % required_spot_type.spot_type_id
