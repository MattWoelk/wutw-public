class_name Tutorial_Salvage
extends TutorialBase

var _salvage: Salvage

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func _on_run_state_changed() -> void:
	var run := Utils.get_active_run()
	if run.get_state() == RunData.State.SEASON_END:
		var season_end := run.get_current_scene() as SeasonEnd
		season_end.salvage_opened.connect(func(salvage: Salvage) -> void:
			_salvage = salvage
			ready_to_trigger.emit()
		)
		# Don't need to disconnect, since if the tutorial is reset, the season end screen must be dead.

func trigger() -> void:
	await Utils.get_active_run().get_tree().create_timer(1.5).timeout  # Wait for animation.
	var text := tr('''
At the end of each <term_lower:season>, you can select a <term_lower:glyph> to <term_lower:salvage>. \
This will remove it from your <term_lower:card_deck> and add its <term_lower:stroke>s to your \
inventory for <term_lower:craft>ing new <term_lower:glyph>.
''').strip_edges()
	var panel := _salvage.get_node('ScrollPanel') as Control
	_outline_controls([panel])
	_show_tooltip(panel, text, [Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'salvage'
