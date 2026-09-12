class_name Tutorial_CraftConnection
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	if Skill.get_skill_var(Skill.Var.CAPITAL_CRAFT_CONNECTION):
		Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	if Skill.get_skill_var(Skill.Var.CAPITAL_CRAFT_CONNECTION):
		Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 30

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
<term:connect_settlement>ing <term_lower:settlement>s requires <term:aspect.connection> <term_lower:aspect>.

If you don't have enough, <term_lower:fill> these <term_lower:aspect_slot>s to gain a random <term_lower:glyph> with <term:aspect.connection> <term_lower:aspect>.
''').strip_edges()

	var connection_recipe := capital.get_node('%ConnectionRecipe') as Control
	var unshaded: Array[Control] = [capital.get_node('%RecipesBox')]
	_outline_controls([connection_recipe], false, unshaded)
	_show_tooltip(connection_recipe, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'harmonization_craft_connection'
