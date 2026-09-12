@tool
class_name Relic_StoneNeedle
extends Relic

@export var hand_size_increase: int = 2
@export var hurt_amount: int = 1

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)
	_run.signals.card_cast_finished.connect(_on_card_cast)
	if apply_modifiers:
		_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	_run.get_vars().remove_modifier(_get_modifier_tag())
	super.on_removed()

func _on_card_slotted(_card: Card, _aspect_slot: AspectSlot) -> void:
	_on_card_played()

func _on_card_cast(_card: Card) -> void:
	_on_card_played()

func _on_card_played() -> void:
	_run.run_or_queue_action(func() -> void:
		triggered.emit()
		_run.modify_inspiration(-hurt_amount, Run.InspirationChangeReason.RELIC)
		await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % [hand_size_increase, hurt_amount]
