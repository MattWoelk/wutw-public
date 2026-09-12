class_name Tutorial_Haunting
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.foray_started.connect(_on_stage_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.foray_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	if _get_haunting():
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(1.5).timeout  # Let stage UI finish animating.

	var text := tr('''
You have encountered your first <term:haunting>!

These spirits will pose extra challenges during <term_lower:foray>s from now on.

Hauntings connected to a <term_lower:spot> by a red thread affect only that <term_lower:spot>, while unconnected hauntings affect the whole settlement.

You can pacify these spirits by <term_lower:fill>ing their associated <term_lower:aspect_slot>s.
''').strip_edges()

	var haunting := _get_haunting()
	var stage := run.get_current_stage()
	stage.ensure_slot_visible(haunting.get_aspect_slots()[0])
	_outline_controls([haunting])
	_show_tooltip(haunting, text, [Tooltip.RelativeDirection.BELOW, Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'haunting'

func _get_haunting() -> HauntingBase:
	var hauntings := Utils.get_active_run().get_current_stage().get_hauntings()
	if hauntings:
		return hauntings[0]
	else:
		return null
