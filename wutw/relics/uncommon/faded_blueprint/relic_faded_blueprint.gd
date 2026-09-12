@tool
class_name Relic_FadedBlueprint
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_state = State.ACTIVE
