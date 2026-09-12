class_name Tutorial_UniversalSlots
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func get_tutorial_order() -> int:
	return 10

func start_listening() -> void:
	Utils.get_active_run().signals.stage_started.connect(_on_stage_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.stage_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	_check_slots()
	var survey := Utils.get_active_run().get_current_stage().get_survey()
	if survey:
		survey.episode_started.connect(func(_episode: SurveyEpisode) -> void: _check_slots())

func _check_slots() -> void:
	for slot in Utils.get_active_run().get_current_stage().get_all_aspect_slots(true):
		if slot.is_universal:
			ready_to_trigger.emit()
			return

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(0.5).timeout  # Let stage UI finish animating.

	var text := tr('''
This is a universal <term_lower:aspect_slot>.

It will accept any kind of <term_lower:aspect>.
''').strip_edges()

	var universal_slot: AspectSlot
	for slot in Utils.get_active_run().get_current_stage().get_all_aspect_slots(true):
		if slot.is_universal:
			universal_slot = slot
			break
	assert(universal_slot)

	_outline_controls([universal_slot], false, [], Vector2(10, 10))
	_show_tooltip(universal_slot, text, [Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'universal_slots'
