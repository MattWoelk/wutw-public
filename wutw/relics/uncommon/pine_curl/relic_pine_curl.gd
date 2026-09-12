@tool
class_name Relic_PineCurl
extends Relic

@export var bonus_heal_percent: int = 50

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.inspiration_gained.connect(_on_inspiration_gained)

func on_removed() -> void:
	_run.signals.inspiration_gained.disconnect(_on_inspiration_gained)
	super.on_removed()

func _on_inspiration_gained(amount: int, _reason: Run.InspirationChangeReason) -> void:
	var extra_amount := roundi(amount * bonus_heal_percent / 100.0)
	# IMPORTANT: Not going through Run.modify_inspiration() to not trigger the event.
	_run.get_vars().modify_base_value(RunVars.Var.CURRENT_INSPIRATION, extra_amount)
	triggered.emit()

func get_description() -> String:
	return tr(default_description) % bonus_heal_percent
