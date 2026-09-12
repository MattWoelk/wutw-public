@tool
class_name SurveyPrepButton
extends VBoxContainer

signal pressed

@export var action_label: String = tr('Do something'):
	set(value):
		action_label = value
		if is_node_ready():
			_recreate()
@export var outcome_label: String = tr('Get this reward.'):
	set(value):
		outcome_label = value
		if is_node_ready():
			_recreate()
@export var bonus_type: BonusType:
	set(value):
		bonus_type = value
		if is_node_ready():
			_recreate()
@export var base_cost: int = 50:
	set(value):
		base_cost = value
		if is_node_ready():
			_recreate()
@export var cost_per_season: int = 50:
	set(value):
		cost_per_season = value
		if is_node_ready():
			_recreate()
@export var run_var: RunVars.Var:
	set(value):
		run_var = value
		if is_node_ready():
			_recreate()
@export var run_var_delta: int = 0:
	set(value):
		run_var_delta = value
		if is_node_ready():
			_recreate()
@export var max_uses: int = 2:
	set(value):
		max_uses = value
		if is_node_ready():
			_update_state()

var _times_used := 0

func _ready() -> void:
	_recreate()
	var run := Utils.get_active_run()
	if run:
		run.signals.bonus_gained.connect(_update_state.unbind(3))
		run.signals.bonus_lost.connect(_update_state.unbind(3))

func get_times_used() -> int:
	return _times_used

func _recreate() -> void:
	if not bonus_type:
		return
	(%ButtonLabel as MarkedUpLabel).set_markedup_text('[lb]%d %s[rb] %s' %
		[_get_cost(), bonus_type.get_term_tag(), tr(action_label)])
	(%OutcomeLabel as MarkedUpLabel).set_markedup_text(tr(outcome_label))
	_update_state()

func _on_button_pressed() -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	assert(stage)
	_times_used += 1
	stage.add_modifier(run_var, run_var_delta)
	run.gain_bonus(BonusGain.new(bonus_type, -_get_cost(), self))
	pressed.emit()

func _update_state() -> void:
	if Utils.is_in_editor():
		return
	var run := Utils.get_active_run()
	var enough_bonus := run.get_bonus_amounts().get_amount(bonus_type) >= _get_cost()
	(%Button as Button).disabled = (not enough_bonus) or _times_used >= max_uses

func _get_cost() -> int:
	if Utils.is_in_editor():
		return base_cost
	else:
		return base_cost + Utils.get_active_run().get_current_season_index() * cost_per_season
