@tool
class_name Relic_OracleBone
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.ability_started.connect(_on_ability_started)

func on_removed() -> void:
	_run.signals.ability_started.disconnect(_on_ability_started)
	super.on_removed()

func _on_ability_started(_card: Card, ability: CardAbility) -> void:
	if ability is CardAbility_Divine:
		# The actual effect is handled through var modifiers, but we should still emit a notification.
		triggered.emit()
