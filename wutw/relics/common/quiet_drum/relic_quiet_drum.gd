@tool
class_name Relic_QuietDrum
extends Relic

@export var max_played_cards: int = 3
@export var hand_size_increase: int = 2

# Not saved because it's only used within a single stage.
var _cards_played: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.redraw_started.connect(_on_redraw_started)
	_run.signals.redraw_finished.connect(_on_redraw_finished)
	_run.signals.card_slotted.connect(_on_card_slotted)
	_run.signals.card_cast_finished.connect(_on_card_cast)

func on_removed() -> void:
	_run.signals.redraw_started.disconnect(_on_redraw_started)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	super.on_removed()

func get_current_counter() -> int:
	return _cards_played

func get_max_counter() -> int:
	return max_played_cards

func _on_stage_started() -> void:
	_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())
	_cards_played = 0
	counter_changed.emit()

func _on_redraw_finished(_is_first: bool) -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag())
	_state = State.ACTIVE
	_cards_played = 0
	counter_changed.emit()

func _on_redraw_started(is_first: bool) -> void:
	if not is_first and _cards_played <= max_played_cards:
		_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())
		triggered.emit()

func _on_card_slotted(_card: Card, _aspect_slot: AspectSlot) -> void:
	_on_card_played()

func _on_card_cast(_card: Card) -> void:
	_on_card_played()

func _on_card_played() -> void:
	_cards_played += 1
	counter_changed.emit()
	if _cards_played > max_played_cards:
		_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % [max_played_cards, hand_size_increase]
