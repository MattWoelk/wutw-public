class_name Tutorial_SkillQuest
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	Utils.get_active_hub().menu_opened.connect(_on_hub_menu_opened)

func stop_listening() -> void:
	Utils.get_active_hub().menu_opened.disconnect(_on_hub_menu_opened)

func _on_hub_menu_opened(menu: Node) -> void:
	if menu is SkillManagement:
		var quest_instance := GlobalSaveGame.get_quest_instance(load('res://quests/main/phase1/1_25_crafting/quest_main_1_25_crafting.tres') as Quest)
		if quest_instance and quest_instance.is_active():
			ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	var skill_management := hub.get_opened_menu() as SkillManagement

	await hub.get_tree().create_timer(1.5).timeout  # Let unroll animation finish.

	var inscribe_skill_node: SkillNode
	for tree in skill_management.get_node('%TreesList').get_children():
		for child in tree.get_children():
			if child is SkillNode:
				var skill_node := child as SkillNode
				if skill_node.skill == load('res://skills/craft/skill_craft_1_common.tres'):
					inscribe_skill_node = skill_node
					break
	var text := tr('''
This is the [b]%s[/b] skill.

It will allow you to <term_lower:craft> <term_lower:glyph>s to start with on future <term_lower:run>s.
''').strip_edges() % tr(inscribe_skill_node.skill.skill_name)
	_outline_controls([inscribe_skill_node])
	_show_tooltip(inscribe_skill_node, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'skill_quest'
