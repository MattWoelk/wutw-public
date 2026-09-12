@tool
class_name Relic_StoneHeart
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.pre_inspiration_gained.connect(_on_pre_inspiration_gained)

func on_removed() -> void:
	_run.signals.pre_inspiration_gained.disconnect(_on_pre_inspiration_gained)
	super.on_removed()

func _on_pre_inspiration_gained(amount: int, _reason: Run.InspirationChangeReason) -> void:
	# Effect is applied through vars, but still want to trigger anim.
	if amount < 0:
		triggered.emit()
