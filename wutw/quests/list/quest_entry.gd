class_name QuestEntry
extends VBoxContainer

static var QUEST_GOAL_ENTRY_SCENE := AsyncLoadedResource.new('res://quests/list/quest_goal_entry.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)

var quest_instance: QuestInstance:
	set(value):
		if quest_instance:
			quest_instance.changed.disconnect(_update)
		quest_instance = value
		if quest_instance:
			value.changed.connect(_update)
		_update()

func _ready() -> void:
	_update()
	Utils._scale_font_size(%NameLabel as MarkedUpLabel, true, 16)

func _update() -> void:
	if not quest_instance or not is_node_ready():
		return

	var title := tr(quest_instance.get_quest().name)
	if quest_instance.get_quest() is Quest_Settler:
		title = tr('Settler Quest: ') + '[color=%s][url=museum_settler_quest:%s]%s[/url][/color]' % [
			Term.LINK_COLOR.to_html(), quest_instance.get_quest().quest_id, title]
	(%NameLabel as MarkedUpLabel).set_markedup_text('[b]%s[/b]' % title, MarkedUpLabel.LinkMode.LINK)

	Utils.clear_node(self, 1)
	for goal_state in quest_instance.get_current_goals():
		var quest_goal_entry := QUEST_GOAL_ENTRY_SCENE.instantiate_loaded_scene() as QuestGoalEntry
		quest_goal_entry.text = goal_state.text  # Already translated.
		quest_goal_entry.completed = goal_state.completed
		add_child(quest_goal_entry)
