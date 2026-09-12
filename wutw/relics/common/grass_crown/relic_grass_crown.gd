@tool
class_name Relic_GrassCrown
extends Relic

@export var spot_type: SpotType
@export var num_to_trigger: int = 10
@export var protection_percent: int = 10

var _num_triggered := 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.spot_recipe_activated.connect(_on_recipe_activated)

func on_removed() -> void:
	_run.signals.spot_recipe_activated.disconnect(_on_recipe_activated)
	super.on_removed()

func get_current_counter() -> int:
	return _num_triggered

func get_max_counter() -> int:
	return num_to_trigger

func save_data() -> Dictionary:
	var result := super.save_data()
	result['num_triggered'] = _num_triggered
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_num_triggered = encoded_data.get('num_triggered', 0)

func _on_recipe_activated(spot_recipe: SpotRecipe) -> void:
	if _state == State.ACTIVE and spot_recipe.spot_upgrade.spot == spot_type:
		_run.run_or_queue_action(func() -> void:
			_num_triggered += 1
			triggered.emit()
			counter_changed.emit()
			if _num_triggered >= num_to_trigger:
				_run.get_vars().add_modifier(RunVars.Var.INSPIRATION_LOSS_PERCENT, -protection_percent, _get_modifier_tag())
				_state = State.EXPIRED
			await _brief_wait()
		)

func get_description() -> String:
	var text := tr(default_description) % [num_to_trigger, spot_type.spot_type_id, protection_percent]
	if _state == State.EXPIRED:
		text += '\n\n'
		text += tr('[b]This goal has already been achieved and the bonus is now active.[/b]')
	return text
