@tool
class_name Quest
extends Resource

enum Category { MAIN, COMPANION, SETTLER }

static var _group_loader := AsyncLoadedGroup.new('res://quests/resourcegroup_quests.tres')
static var _all_quests: Dictionary[String, Quest]

@export var quest_id: String
@export var category: Category = Category.MAIN
@export var name: String
@export var goals: Array[String]

static func get_all_quests() -> Dictionary[String, Quest]:
	if not _all_quests:
		for quest: Quest in _group_loader.get_loaded():
			assert(quest.quest_id)
			if quest.quest_id in _all_quests:
				push_error('Duplicate quest ID "%s":\n- %s\n- %s' %
						[quest.quest_id, quest.resource_path, _all_quests[quest.quest_id].resource_path])
			_all_quests[quest.quest_id] = quest
	return _all_quests

static func get_quest_by_id(id: String) -> Quest:
	return get_all_quests().get(id)

func instantiate(initial_state: int = QuestInstance.STATE_ACTIVE, initial_goals_completed: Array[bool] = []) -> QuestInstance:
	if not initial_goals_completed:
		initial_goals_completed.resize(get_decorated_goals().size())
	# For subclasses to extend, connecting to events, etc.
	return QuestInstance.new(self, initial_state, initial_goals_completed)

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	assert(run)
	# For subclasses to implement.

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	assert(run)
	# For subclasses to implement.

func on_hub_entered(instance: QuestInstance, hub: Hub) -> void:
	assert(instance)
	assert(hub)
	# For subclasses to implement.

func on_hub_exited(instance: QuestInstance, hub: Hub) -> void:
	assert(instance)
	assert(hub)
	# For subclasses to implement.

func get_decorated_goals() -> Array[String]:
	# For subclasses to override.
	var result: Array[String]
	for goal in goals:
		result.append(tr(goal))
	return result

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return []
