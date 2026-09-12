@tool
class_name Relic_OwlFigurine
extends Relic

@export var aspect_type: AspectType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	super.on_removed()

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	if aspect_type in card.card_type.aspects:
		triggered.emit()
		_run.grant_insights(1)
		await _brief_wait()

func get_description() -> String:
	return tr(default_description) % aspect_type.get_term_tag()
