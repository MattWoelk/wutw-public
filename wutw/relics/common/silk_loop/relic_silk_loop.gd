@tool
class_name Relic_SilkLoop
extends Relic

# Not saved because it's only used within a single stage.
var discard_blocked_this_stage: bool = false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.ability_started.connect(_on_ability_started)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.ability_started.disconnect(_on_ability_started)
	super.on_removed()

func _on_stage_started() -> void:
	discard_blocked_this_stage = false
	_state = State.ACTIVE

func _on_ability_started(_card: Card, ability: CardAbility) -> void:
	# Has to be synchronous, not queued.
	if not discard_blocked_this_stage and ability is CardAbility_Discard:
		discard_blocked_this_stage = true
		_run.get_vars().set_base_value(RunVars.Var.ABILITY_CASTS_BLOCKED, 1)
		triggered.emit()
		_state = State.PASSIVE
