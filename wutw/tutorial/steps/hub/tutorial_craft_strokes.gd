class_name Tutorial_Craft_Strokes
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	Utils.get_active_hub().menu_opened.connect(_on_hub_menu_opened)

func stop_listening() -> void:
	Utils.get_active_hub().menu_opened.disconnect(_on_hub_menu_opened)

func get_tutorial_order() -> int:
	return 20

func _on_hub_menu_opened(menu: Node) -> void:
	if menu is Crafting:
		ready_to_trigger.emit()

func trigger() -> void:
	var crafting := Utils.get_active_hub().get_opened_menu() as Crafting
	var strokes_list := crafting.get_node('%StrokesPanel') as Control
	var text := tr('''
<term:glyph>s require <term_lower:stroke>s to be <term_lower:craft>d.

These are acquired when you <term_lower:salvage> <term_lower:glyph>s at the end of each completed <term_lower:season>.
''').strip_edges()

	_outline_controls([strokes_list])
	_show_tooltip(strokes_list, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'craft_strokes'
