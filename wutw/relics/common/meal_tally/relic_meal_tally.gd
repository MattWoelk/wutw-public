@tool
class_name Relic_MealTally
extends Relic

@export var num_to_trigger: int = 3

var _activations_left_to_trigger: int = num_to_trigger

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.spot_recipe_activated.connect(_on_recipe_activated)
	_activations_left_to_trigger = num_to_trigger  # In case we ever add relics mid-stage.
	if _run.get_current_stage():
		_on_stage_started()

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.spot_recipe_activated.disconnect(_on_recipe_activated)
	super.on_removed()

func get_current_counter() -> int:
	return num_to_trigger - _activations_left_to_trigger

func get_max_counter() -> int:
	return num_to_trigger

func save_data() -> Dictionary:
	var result := super.save_data()
	result['counter'] = _activations_left_to_trigger
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_activations_left_to_trigger = encoded_data.get('counter', num_to_trigger)

func _on_stage_started() -> void:
	if _run.get_current_stage().mode == Stage.Mode.REGULAR:
		_state = State.ACTIVE
	else:
		_state = State.PASSIVE

func _on_recipe_activated(_spot_recipe: SpotRecipe) -> void:
	_activations_left_to_trigger -= 1
	if _activations_left_to_trigger == 0:
		_activations_left_to_trigger = num_to_trigger
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _run.get_current_stage().get_card_deck().draw(CardDeck.CardDrawReason.RELIC, true)
		)
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % num_to_trigger
