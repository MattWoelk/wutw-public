class_name Tutorial_Lacks
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 10

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.HARMONIZATION:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()

	# Wait until we're done zooming.
	await run.get_tree().process_frame

	var map := run.get_map()
	var settlement := run.get_settlements()[0]
	map.focus_location(settlement.state.map_location, map.max_zoom, 0.5)
	map.view_controls_enabled = false
	await Utils.wait_with_timeout(map.is_camera_moving, 5.0)
	map.view_controls_enabled = true

	var text := tr('''
The goal of <term:harmonization> is to <term_lower:satisfy_lack> <term_lower:settlement> <term_lower:lack>s.

For example, this <term_lower:settlement> has a <term_lower:lack> of %s.

To <term_lower:satisfy_lack> a <term_lower:lack>, <term_lower:fill> these <term_lower:aspect_slot>s.
''').strip_edges() % settlement.get_unsatisfied_lacks()[0].get_term_tag()

	var lack_recipe := settlement.get_node('%LackRecipe1') as Control
	var unshaded: Array[Control] = [settlement.get_node('%RadiusIndicatorFrame'), settlement.get_node('%NameBox'), settlement.get_node('%RecipesBox')]
	_outline_controls([lack_recipe], false, unshaded)
	_show_tooltip(lack_recipe, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'harmonization_lacks'
