class_name Tutorial_Studio
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	GlobalSaveGame.changed.connect(_on_savegame_changed)
	_on_savegame_changed()

func stop_listening() -> void:
	GlobalSaveGame.changed.disconnect(_on_savegame_changed)

func _on_savegame_changed() -> void:
	if Skill.get_skill_var(Skill.Var.INSCRIBE_COMMON):
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().process_frame  # Make sure size is updated.

	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var studio := hub.get_node('%HubContent').get_node('%Studio').get_node('TooltipAnchor') as Control
	var text := tr('''
You can <term_lower:craft> new <term_lower:glyph>s here.

<term:craft>d <term_lower:glyph>s can be chosen as your <term:signature_card>.
''').strip_edges()

	_outline_controls([studio])
	_show_tooltip(studio, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'studio'
