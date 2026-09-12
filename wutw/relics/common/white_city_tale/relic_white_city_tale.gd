@tool
class_name Relic_WhiteCityTale
extends Relic

@export var spot_type: SpotType
@export var bonus_type: BonusType
@export var gain_amount: int = 1

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.spot_recipe_activated.connect(_on_spot_recipe_activated)
	if _run.get_current_stage():
		_on_stage_started()

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.spot_recipe_activated.disconnect(_on_spot_recipe_activated)
	super.on_removed()

func _on_stage_started() -> void:
	var stage := _run.get_current_stage()
	if stage.mode == Stage.Mode.REGULAR and spot_type in stage.settlement.state.spot_types:
		_state = State.ACTIVE
	else:
		_state = State.PASSIVE

func _on_spot_recipe_activated(spot_recipe: SpotRecipe) -> void:
	if spot_recipe.spot_upgrade.spot != spot_type:
		return
	if spot_recipe.spot_upgrade.granted_bonuses.get(bonus_type, 0) <= 0:
		return
	_run.run_or_queue_action(func() -> void:
		_run.get_vars().add_modifier(RunVars.Var.MAX_INSPIRATION, gain_amount, _get_modifier_tag(Utils.generate_guid()))
		triggered.emit()
		await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % [bonus_type.get_term_tag(), spot_type.spot_type_id, gain_amount]
