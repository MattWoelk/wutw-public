class_name Tutorial_CapitalSkills
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	var quest_instance := GlobalSaveGame.get_quest_instance(
		load('res://quests/main/phase1/1_20_capital/quest_main_1_20_capital.tres') as Quest)
	if not quest_instance:
		return
	if quest_instance.is_ready_to_finish() or quest_instance.is_finished():
		mark_skipped()
		return
	if GlobalSaveGame.get_main_quest_progress() == SaveGame.MainQuestProgress.P118_REACHED_CONVERGENCE:
		ready_to_trigger.emit()

func stop_listening() -> void:
	pass  # Triggers on hub start.

func get_tutorial_order() -> int:
	return 20

func trigger() -> void:
	var hub := Utils.get_active_hub()
	var shrine := hub.get_node('%HubContent').get_node('%Shrine').get_node('TooltipAnchor') as Control
	var text := tr('''
You can find alternative ways to complete the <term:harmonization> \
 in the <term:capital> <term_lower:skill> tree!
''').strip_edges()
	_outline_controls([shrine])
	_show_tooltip(shrine, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'capital_skills'
