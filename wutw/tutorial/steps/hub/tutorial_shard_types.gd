class_name Tutorial_ShardTypes
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	Utils.get_active_hub().menu_opened.connect(_on_hub_menu_opened)

func stop_listening() -> void:
	Utils.get_active_hub().menu_opened.disconnect(_on_hub_menu_opened)

func get_tutorial_order() -> int:
	return 10

func _on_hub_menu_opened(menu: Node) -> void:
	if menu is ShardExplorer:
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().create_timer(1.0).timeout  # HACK: Wait for menu unroll animation.

	var shard_explorer := Utils.get_active_hub().get_opened_menu() as ShardExplorer
	var types_list := shard_explorer.get_node('%ScrollContainer') as Control
	var text := tr('''
This is a list of potential <term_lower:shard_type>s.

Some are part of the main story, but most can arise on any shard under certain conditions.

Over time, each <term_lower:shard_type> will develop its own history.
''').strip_edges()

	_outline_controls([types_list])
	_show_tooltip(types_list, text, [Tooltip.RelativeDirection.RIGHT])

func get_skip_id() -> String:
	return 'shard_types'
