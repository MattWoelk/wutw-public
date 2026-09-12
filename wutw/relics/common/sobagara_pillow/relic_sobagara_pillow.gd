@tool
class_name Relic_SobagaraPillow
extends Relic

@export var heal_amount: int = 3

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_reward_skipped.connect(_on_card_reward_skipped)

func on_removed() -> void:
	_run.signals.card_reward_skipped.disconnect(_on_card_reward_skipped)
	super.on_removed()

func _on_card_reward_skipped() -> void:
	triggered.emit()
	_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)

func get_description() -> String:
	return tr(default_description) % heal_amount
