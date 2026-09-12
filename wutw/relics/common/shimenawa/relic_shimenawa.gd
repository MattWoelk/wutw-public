@tool
class_name Relic_Shimenawa
extends Relic

@export var life: AspectType
@export var spirit: AspectType
@export var connection: AspectType
@export var added_card: CardType

var _life_slotted := false
var _spirit_slotted := false
var _connection_slotted := false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.aspect_slot_filled.connect(_on_aspect_slot_filled)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.aspect_slot_filled.disconnect(_on_aspect_slot_filled)
	super.on_removed()

func _on_stage_started() -> void:
	_spirit_slotted = false
	_life_slotted = false
	_connection_slotted = false
	_state = State.ACTIVE

func _on_aspect_slot_filled(aspect_slot: AspectSlot) -> void:
	if _state != State.ACTIVE:
		return

	if aspect_slot.aspect_type == life:
		_life_slotted = true
	if aspect_slot.aspect_type == spirit:
		_spirit_slotted = true
	if aspect_slot.aspect_type == connection:
		_connection_slotted = true

	if _life_slotted and _spirit_slotted and _connection_slotted:
		_run.run_or_queue_action(func() -> void:
			if _state != State.ACTIVE:
				return
			triggered.emit()
			var deck := _run.get_current_stage().get_card_deck()
			await deck.add_card_to_draw_pile(added_card)
			_state = State.PASSIVE
		)

func get_description() -> String:
	return tr(default_description) % [life.get_term_tag(), spirit.get_term_tag(), connection.get_term_tag(), added_card.get_term_tag()]
