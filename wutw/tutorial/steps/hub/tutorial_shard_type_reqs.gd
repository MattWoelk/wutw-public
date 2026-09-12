class_name Tutorial_ShardType_Reqs
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
	if menu is ShardExplorer:
		ready_to_trigger.emit()

func trigger() -> void:
	var shard_explorer := Utils.get_active_hub().get_opened_menu() as ShardExplorer
	var shard_details := shard_explorer.get_node('%ShardDetails') as ShardDetails

	# Make sure a locked one is chosen.
	if GlobalSaveGame.is_shard_type_unlocked(shard_details.shard_type):
		for button: ShardTypeButton in shard_explorer.get_node('%TypesList').get_children():
			if not GlobalSaveGame.is_shard_type_unlocked(button.shard_type):
				button.button_pressed = true  # Doesn't emit pressed.
				button.pressed.emit()
				break
	assert(not GlobalSaveGame.is_shard_type_unlocked(shard_details.shard_type))

	var reqs_label := shard_details.get_node('%RequirementsLabel') as Control

	var text := tr('''
These are the conditions under which the selected <term_lower:shard_type> will arise.

If they are fulfilled during an <term_lower:run>, that shard will develop this culture.

If the conditions for multiple <term_lower:shard_type>s are fulfilled in the same <term_lower:run>, only one culture will be chosen.
''').strip_edges()

	_outline_controls([reqs_label], false, [], Vector2(8, 8))
	_show_tooltip(reqs_label, text, [Tooltip.RelativeDirection.LEFT, Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'shard_type_reqs'
