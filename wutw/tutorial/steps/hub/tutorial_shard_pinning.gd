class_name Tutorial_ShardType_Pinning
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	Utils.get_active_hub().menu_opened.connect(_on_hub_menu_opened)

func stop_listening() -> void:
	Utils.get_active_hub().menu_opened.disconnect(_on_hub_menu_opened)

func get_tutorial_order() -> int:
	return 30

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

	var pin_button := shard_details.get_node('%PinButton') as Control

	var text := tr('''
This button pins the <term_lower:shard_type> to your quest list.

If you start an <term_lower:run> with a culture pinned,\
 settlers will try to pick a shard appropriate for fulfilling the requirements.
''').strip_edges()

	_outline_controls([pin_button])
	_show_tooltip(pin_button, text, [Tooltip.RelativeDirection.RIGHT, Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'shard_pinning'
