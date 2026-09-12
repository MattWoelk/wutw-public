@tool
class_name Relic_BellChain
extends Relic

@export var num_cards_to_trigger: int = 4

var _cards_played: int = 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.card_slotted.connect(_on_card_slotted)
	_run.signals.card_cast_finished.connect(_on_card_cast)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	super.on_removed()

func get_current_counter() -> int:
	return _cards_played

func get_max_counter() -> int:
	return num_cards_to_trigger

func _on_stage_started() -> void:
	_cards_played = 0
	_state = State.ACTIVE
	counter_changed.emit()

func _on_card_slotted(_card: Card, _aspect_slot: AspectSlot) -> void:
	_on_card_played()

func _on_card_cast(_card: Card) -> void:
	_on_card_played()

func _on_card_played() -> void:
	if _state != State.ACTIVE:
		return

	# Has to be synchronous, not queued.
	_cards_played += 1
	if _cards_played >= num_cards_to_trigger:
		_run.get_vars().set_base_value(RunVars.Var.DISCARDS_BLOCKED, 1)
		triggered.emit()
		_state = State.PASSIVE
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % num_cards_to_trigger
