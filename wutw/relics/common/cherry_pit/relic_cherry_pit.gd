@tool
class_name Relic_CherryPit
extends Relic

@export var spot_type: SpotType
@export var num_to_trigger: int = 10
@export var added_card: CardType

var _num_triggered := 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.spot_recipe_activated.connect(_on_recipe_activated)
	_run.signals.redraw_finished.connect(_on_redraw_finished)

func on_removed() -> void:
	_run.signals.spot_recipe_activated.disconnect(_on_recipe_activated)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
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
	if _num_triggered >= num_to_trigger:
		return  # Already charged.
	if spot_recipe.spot_upgrade.spot == spot_type:
		_run.run_or_queue_action(func() -> void:
			if _num_triggered < num_to_trigger:
				_num_triggered += 1
				triggered.emit()
				counter_changed.emit()
				await _brief_wait()
		)

func _on_redraw_finished(is_first: bool) -> void:
	if _num_triggered < num_to_trigger:
		return  # Still charging.
	if is_first:
		_run.run_or_queue_action(func() -> void:
			_state = State.ACTIVE
			triggered.emit()
			var deck := _run.get_current_stage().get_card_deck()
			await deck.add_card_to_hand(added_card, CardDeck.CardDrawReason.RELIC)
			_state = State.PASSIVE
		)

func get_description() -> String:
	var text := tr(default_description) % [num_to_trigger, spot_type.spot_type_id, added_card.get_term_tag()]
	if _num_triggered >= num_to_trigger:
		text += '\n\n'
		text += tr('[b]The requirement has been met.[/b]')
	return text
