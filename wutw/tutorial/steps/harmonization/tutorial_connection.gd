class_name Tutorial_Connection
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	if Skill.get_skill_var(Skill.Var.CAPITAL_CONNECTION):
		Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	if Skill.get_skill_var(Skill.Var.CAPITAL_CONNECTION):
		Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 20

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.HARMONIZATION:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var map := run.get_map()
	var settlement := run.get_settlements()[0]
	map.focus_location(settlement.state.map_location, map.max_zoom, 0.5)
	map.view_controls_enabled = false
	await Utils.wait_with_timeout(map.is_camera_moving, 5.0)
	map.view_controls_enabled = true

	var provided_yield := settlement.get_yield_type().get_term_tag()
	var text := tr('''
Another way to <term_lower:satisfy_lack> a <term_lower:lack> is to <term_lower:connect_settlement> <term_lower:settlement>s to the <term:capital>.

This settlement provides %s. If you <term_lower:connect_settlement> it to the <term:capital>, %s will be shared with all other connected <term_lower:settlement>s.

If you then <term_lower:connect_settlement> a <term_lower:settlement> that has a %s <term_lower:lack>, that <term_lower:lack> will be <term_lower:satisfy_lack>ed.
''').strip_edges() % [provided_yield, provided_yield, provided_yield]

	var connect_recipe := settlement.get_node('%ConnectRecipe') as Control
	var unshaded: Array[Control] = [settlement.get_node('%RadiusIndicatorFrame'), settlement.get_node('%NameBox'), settlement.get_node('%RecipesBox')]
	_outline_controls([connect_recipe], false, unshaded)
	_show_tooltip(connect_recipe, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'harmonization_connection'
