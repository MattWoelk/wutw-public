@tool
class_name Relic_MendedTeacup
extends Relic

@export var max_per_stage: int = 7

var _total_max_inspiration: int = 0
var _total_this_stage: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.inspiration_lost.connect(_on_inspiration_lost)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.inspiration_lost.disconnect(_on_inspiration_lost)
	_run.get_vars().remove_modifier(_get_modifier_tag())
	super.on_removed()

func save_data() -> Dictionary:
	var result := super.save_data()
	result['gained'] = _total_max_inspiration
	return result

func load_data(encoded_data: Dictionary) -> void:
	super.load_data(encoded_data)
	_total_max_inspiration = encoded_data.get('gained', 0)

func get_current_counter() -> int:
	return _total_this_stage

func get_max_counter() -> int:
	return max_per_stage

func _on_stage_started() -> void:
	_total_this_stage = 0
	counter_changed.emit()
	_state = State.ACTIVE

func _on_inspiration_lost(amount: int, _reason: Run.InspirationChangeReason) -> void:
	if amount > 1:
		_run.run_or_queue_action(func() -> void:
			var to_gain := mini(floori(amount / 2.0), max_per_stage - _total_this_stage)
			if to_gain > 0:
				_total_this_stage += to_gain
				counter_changed.emit()
				_total_max_inspiration += to_gain
				triggered.emit()
				_run.get_vars().add_modifier(RunVars.Var.MAX_INSPIRATION, _total_max_inspiration, _get_modifier_tag())
				await _brief_wait()
				if _total_this_stage >= max_per_stage:
					_state = State.PASSIVE
		)

func get_description() -> String:
	var text := tr(default_description) % max_per_stage
	if _run:
		text += '\n\n'
		text += tr('[b]Maximum <term:inspiration> gained: %d[/b]') % _total_max_inspiration
		if _total_this_stage > 0:
			text += '\n'
			text += tr('[b]Gained this <term_lower:stage>: %d[/b]') % _total_this_stage
	return text
