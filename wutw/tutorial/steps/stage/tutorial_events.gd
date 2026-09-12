class_name Tutorial_Events
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.foray_started.connect(_on_stage_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.foray_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	if _get_event_recipe():
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(1.5).timeout  # Let stage UI finish animating.

	var text := tr('''
<term:spot_upgrade>s outlined with glimmers will trigger <term_lower:event>s.

<term:event>s are little vignettes that can grant powerful <term_lower:glyph>s and <term_lower:relic>s, but could also lead to negative outcomes.
''').strip_edges()

	var event_recipe := _get_event_recipe()
	_outline_controls([event_recipe], false, [], Vector2(10, 10))
	_show_tooltip(event_recipe, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'events'

func _get_event_recipe() -> SpotRecipe:
	for spot in Utils.get_active_run().get_current_stage().get_spots():
		for recipe in spot.get_all_recipes():
			if recipe.event is Event_Stage:  # Not a landmark.
				return recipe
	return null
