class_name Tutorial_CapitalProvisions
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	if Skill.get_skill_var(Skill.Var.CAPITAL_ACTIVATE_PROVISIONS):
		Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	if Skill.get_skill_var(Skill.Var.CAPITAL_ACTIVATE_PROVISIONS):
		Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 40

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.HARMONIZATION:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var map := run.get_map()
	var capital := run.get_capital()
	map.focus_location(capital.map_location, map.max_zoom, 0.5)
	map.view_controls_enabled = false
	await Utils.wait_with_timeout(map.is_camera_moving, 5.0)
	map.view_controls_enabled = true

	var text := tr('''
If you have accumulated enough of a given <term_lower:bonus>, you can <term_lower:fill> these <term_lower:aspect_slot>s to have the <term:capital> provide it automatically.
''').strip_edges()

	var satisfy_recipes: Array[Control] = []
	for child in capital.get_node('%RecipesBox').get_children():
		for recipe in child.get_children():
			if recipe != capital.get_node('%ConnectionRecipe'):
				satisfy_recipes.append(child)
	var unshaded: Array[Control] = [capital.get_node('%RecipesBox')]
	_outline_controls(satisfy_recipes, true, unshaded)
	_show_tooltip(capital.get_node('%RecipesBox') as Control, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'harmonization_provisions'
