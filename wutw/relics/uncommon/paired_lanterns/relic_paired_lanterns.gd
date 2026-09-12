@tool
class_name Relic_PairedLanterns
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.settlement_connected.connect(_on_settlement_connected)

func on_removed() -> void:
	_run.signals.settlement_connected.disconnect(_on_settlement_connected)
	super.on_removed()

func _on_settlement_connected(_settlement: Settlement) -> void:
	_run.run_or_queue_action(func() -> void:
		for settlement in _run.get_settlements():
			if not settlement.is_settlement_connected():
				triggered.emit()
				settlement.connect_to_capital()
				await _brief_wait()
				return
	)
