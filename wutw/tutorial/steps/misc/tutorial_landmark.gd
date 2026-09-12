class_name Tutorial_Landmark
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func _on_run_state_changed() -> void:
	var run := Utils.get_active_run()
	if run.get_state() not in [RunData.State.STAGE_SELECTOR, RunData.State.SURVEY_SELECTOR, RunData.State.CAPITAL_PLACEMENT]:
		return
	if _get_landmark_settlement():
		ready_to_trigger.emit()
	elif run.get_capital() and Skill.get_skill_var(Skill.Var.SHOP_TRADE):
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var map := run.get_map()

	var location: Vector2
	var shop_control: Control
	var settlement := _get_landmark_settlement()
	if settlement:
		location = settlement.get_map_location()
		shop_control = settlement.get_node('%ShopsBox')
	else:
		# Must be the capital, as checked in _on_run_state_changed().
		location = run.get_capital().get_map_location()
		shop_control = run.get_capital().get_node('%ShopButton')
	map.focus_location(location, map.max_zoom, 0.5)
	map.view_controls_enabled = false
	await Utils.wait_with_timeout(map.is_camera_moving, 5.0)
	map.view_controls_enabled = true

	var text := tr('''
You have unlocked a <term:shop>. These have various uses, such as getting rare <term_lower:glyph>s \
or restoring <term:inspiration>. You can use each <term_lower:shop> once between <term_lower:stage>s.
''').strip_edges()

	_outline_controls([shop_control])
	_show_tooltip(shop_control, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'landmark'

func _get_landmark_settlement() -> Settlement:
	for settlement in Utils.get_active_run().get_settlements():
		if settlement.get_shops():
			return settlement
	return null
