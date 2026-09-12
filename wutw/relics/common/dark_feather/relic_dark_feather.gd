@tool
class_name Relic_DarkFeather
extends Relic

@export var amount_restored: int = 3

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.companion_ability_started.connect(_on_companion_ability_started)

func on_removed() -> void:
	_run.signals.companion_ability_started.disconnect(_on_companion_ability_started)
	super.on_removed()

func _on_companion_ability_started(_companion: Companion) -> void:
	_run.run_or_queue_action(func() -> void:
		triggered.emit()
		_run.modify_inspiration(amount_restored, Run.InspirationChangeReason.RELIC)
		await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % amount_restored
