@tool
class_name Relic_CuriousStone
extends Relic

@export var amount_healed: int = 4

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.deck_reshuffled.connect(_on_deck_reshuffled)

func on_removed() -> void:
	_run.signals.deck_reshuffled.disconnect(_on_deck_reshuffled)
	super.on_removed()

func _on_deck_reshuffled() -> void:
	_run.modify_inspiration(amount_healed, Run.InspirationChangeReason.RELIC)
	triggered.emit()

func get_description() -> String:
	return tr(default_description) % amount_healed
