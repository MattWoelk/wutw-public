@tool
class_name Relic_RedString
extends Relic

@export var desired_aspect_type: AspectType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.redraw_started.connect(_on_redraw_started)
	_run.signals.redraw_finished.connect(_on_redraw_finished)
	_run.signals.card_added_to_hand.connect(_on_hand_changed.unbind(3))
	_run.signals.discard_finished.connect(_on_hand_changed.unbind(2))
	if _run.get_current_stage():
		_on_hand_changed()

func on_removed() -> void:
	_run.signals.redraw_started.disconnect(_on_redraw_started)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	_run.signals.card_added_to_hand.disconnect(_on_hand_changed.unbind(3))
	_run.signals.discard_finished.disconnect(_on_hand_changed.unbind(2))
	super.on_removed()

func _on_redraw_started(_is_first: bool) -> void:
	for card in _run.get_current_stage().get_card_deck().get_hand_cards():
		if desired_aspect_type in card.card_type.aspects:
			_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, 1, _get_modifier_tag())
			triggered.emit()
			return

func _on_redraw_finished(_is_first: bool) -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag())

func _on_hand_changed() -> void:
	for card in _run.get_current_stage().get_card_deck().get_hand_cards():
		if desired_aspect_type in card.card_type.aspects:
			_state = State.ACTIVE
			return
	_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % desired_aspect_type.get_term_tag()
