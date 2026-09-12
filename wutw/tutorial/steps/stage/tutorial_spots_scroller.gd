class_name Tutorial_SpotsScroller
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func get_tutorial_order() -> int:
	return 10

func start_listening() -> void:
	Utils.get_active_run().signals.foray_started.connect(_on_stage_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.foray_started.disconnect(_on_stage_started)

func _on_stage_started() -> void:
	var run := Utils.get_active_run()
	await run.get_tree().create_timer(0.5).timeout  # Let stage UI finish animating.
	var scroller := run.get_current_stage().get_node('%SpotsScroller') as ScrollContainer
	if scroller.get_h_scroll_bar().visible:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var scroller := run.get_current_stage().get_node('%SpotsScroller') as ScrollContainer

	var text := tr('''
There are more <term_lower:spot>s than can fit on one screen in this <term_lower:foray>.

You can scroll this list using the %s.
''').strip_edges() % InputPrompts.get_input_markup(InputPrompts.InputType.SCROLL_SITES)

	_outline_controls([scroller], false, [], Vector2(10, 10))
	_show_tooltip(scroller, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'spots_scroller'
