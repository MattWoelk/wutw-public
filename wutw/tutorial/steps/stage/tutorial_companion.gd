class_name Tutorial_Companion
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.stage_started.connect(_on_stage_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.stage_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	if GlobalSaveGame.get_current_companion():
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()

	await run.get_tree().process_frame  # Let UI size settle.

	var text := tr('''
This is your <term:companion>.

If you <term_lower:fill> the companion's <term_lower:aspect_slot>s, you will activate their ability.

Every companion has a unique ability, with different slots and benefits.
''').strip_edges()

	var companion_panel := run.get_current_stage().get_node('%CompanionPanel') as PanelContainer
	var companion := companion_panel.get_child(0) as CompanionRecipe
	var companion_icon := companion.get_node('%TooltipAnchor')  # HACK: Use a proper getter.
	_outline_controls([companion, companion_icon])
	_show_tooltip(companion, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'companion'
