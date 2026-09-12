@tool
class_name Relic_SplitBrush
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_started.connect(_on_stage_started)
	_run.signals.aspect_slot_filled.connect(_on_slot_filled)

func on_removed() -> void:
	_run.signals.foray_started.disconnect(_on_stage_started)
	_run.signals.aspect_slot_filled.disconnect(_on_slot_filled)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_slot_filled(aspect_slot: AspectSlot) -> void:
	_run.run_or_queue_action(func() -> void:
		if _state == State.ACTIVE:
			var spot_recipe := Utils.get_typed_ancestor(aspect_slot, SpotRecipe) as SpotRecipe
			if spot_recipe and spot_recipe.spot_upgrade.required_aspects.size() > 1:
				for other_slot in spot_recipe.get_aspect_slots():
					if other_slot != aspect_slot and not other_slot.is_filled:
						triggered.emit()
						await other_slot.animate_fill()
						_state = State.PASSIVE
						break
	)
