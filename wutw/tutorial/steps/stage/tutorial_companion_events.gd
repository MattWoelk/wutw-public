class_name Tutorial_CompanionEvents
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
<term:spot_upgrade>s outlined with green glimmers will trigger <term_lower:event>s that may \
start or continue a quest to unlock a <term:companion>, but only if your choice \
aligns with the companion's wellbeing and cultural symbolism.

If it doesn't, you'll get to try again on a different <term_lower:run>.
''').strip_edges()

	var event_recipe := _get_event_recipe()
	_outline_controls([event_recipe], false, [], Vector2(10, 10))
	_show_tooltip(event_recipe, text,
				  [Tooltip.RelativeDirection.BELOW,
				   Tooltip.RelativeDirection.LEFT,
				   Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'companion_events'

func _get_event_recipe() -> SpotRecipe:
	for spot in Utils.get_active_run().get_current_stage().get_spots():
		for recipe in spot.get_all_recipes():
			if recipe.event is Event_Stage and Event.Category.COMPANION in recipe.event.categories:
				return recipe
	return null
