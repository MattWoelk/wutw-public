@tool
class_name Relic_WeaversComb
extends Relic

@export var base_hand_size_reduction: int = 1
@export var cards_per_increase: int = 10
@export var max_increase: int = 5

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	if apply_modifiers:
		_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, -base_hand_size_reduction, _get_modifier_tag('reduction'))
	_run.signals.card_added.connect(_on_deck_changed)
	_run.signals.card_removed.connect(_on_deck_changed)
	_on_deck_changed(null)

func on_removed() -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag('reduction'))
	_run.get_vars().remove_modifier(_get_modifier_tag('increase'))
	_run.signals.card_added.disconnect(_on_deck_changed)
	_run.signals.card_removed.disconnect(_on_deck_changed)
	super.on_removed()

func _on_deck_changed(_card_type: CardType) -> void:
	@warning_ignore('integer_division')
	_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, _get_hand_size_increase(), _get_modifier_tag('increase'))
	counter_changed.emit()

func get_current_counter() -> int:
	return _get_hand_size_increase() - base_hand_size_reduction

func get_description() -> String:
	var text := tr(default_description) % [base_hand_size_reduction, cards_per_increase, max_increase]
	if _run:
		text += '\n\n'
		text += tr('[b]Current Effect: %+d <term:hand_size>[/b]') % get_current_counter()
	return text

func _get_hand_size_increase() -> int:
	@warning_ignore('integer_division')
	return mini(max_increase, _run.get_deck_cards().size() / cards_per_increase)
