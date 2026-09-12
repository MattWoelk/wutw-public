class_name QuestAnnouncement
extends Node2D

static var QUEST_GOAL_ENTRY_SCENE := AsyncLoadedResource.new('res://quests/list/quest_goal_entry.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

var _pending: Array[QuestInstance]
var _displayed_quest: QuestInstance

func _ready() -> void:
	GlobalSaveGame.quest_started.connect(_on_quest_started)
	GlobalSaveGame.quest_finished.connect(_on_quest_finished)
	GlobalUI.dialogue_ended.connect(_check_for_updates)

func _enter_tree() -> void:
	visible = false

func _on_quest_started(quest_instance: QuestInstance) -> void:
	_pending.append(quest_instance)
	if not visible:
		_check_for_updates()

func _on_quest_finished(quest_instance: QuestInstance) -> void:
	_pending.append(quest_instance)
	if not visible:
		_check_for_updates()

func _process(_delta: float) -> void:
	if GlobalUI.is_higher_level_active(self):
		visible = false

func _check_for_updates() -> void:
	if _pending:
		if visible:
			await (%ScrollPanel as ScrollPanel).animate_roll(0.5, false)
			_update_content(_pending.pop_front() as QuestInstance)
			(%ScrollPanel as ScrollPanel).animate_unroll(0.5, false)
		else:
			_update_content(_pending.pop_front() as QuestInstance)
			_show()

func _show() -> void:
	visible = true
	(%BG as FadedBackground).fade_in()
	(%ScrollPanel as ScrollPanel).animate_unroll()
	GlobalAudioSystem.play(AK.EVENTS.SFX_MAP_QUEST_NEW)

func _hide() -> void:
	_displayed_quest = null
	(%BG as FadedBackground).fade_out()
	await (%ScrollPanel as ScrollPanel).animate_roll()
	visible = false

func _update_content(quest_instance: QuestInstance) -> void:
	_displayed_quest = quest_instance
	(%TitleLabel as Label).text = (
		tr('Quest Finished') if quest_instance.is_finished()
		else tr('New Quest'))
	(%TitleLabel as Label).text += tr(': ') + tr(quest_instance.get_quest().name)
	Utils.clear_node(%GoalsList)
	for goal_state in quest_instance.get_current_goals():
		var quest_goal_entry := QUEST_GOAL_ENTRY_SCENE.instantiate_loaded_scene() as QuestGoalEntry
		quest_goal_entry.text = goal_state.text  # Already translated.
		quest_goal_entry.completed = goal_state.completed
		%GoalsList.add_child(quest_goal_entry)

	if quest_instance.get_quest() is Quest_Settler and quest_instance.is_finished():
		(%RewardPanel as Control).visible = true
		(%ContinueButton as Control).visible = false
		var settler_quest := quest_instance.get_quest() as Quest_Settler
		Utils.clear_node(%RewardsList, 1)
		for reward in settler_quest.rewards:
			var widget := reward.grant(settler_quest, Utils.get_active_run())
			widget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			%RewardsList.add_child(widget)
			await widget.finished
		(%ContinueButton as Control).visible = true
	else:
		(%RewardPanel as Control).visible = false

func _on_continue_button_pressed() -> void:
	if _pending:
		_check_for_updates()
	else:
		_hide()
