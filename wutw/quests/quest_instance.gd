class_name QuestInstance
extends Object

const STATE_INACTIVE: int = 0
const STATE_ACTIVE: int = 100
const STATE_READY_TO_FINISH: int = 200
const STATE_FINISHED: int = 300

signal changed
signal goal_finished

var _quest: Quest
var _state: int
var _listening_active: bool = false
var _goals_completed: Array[bool]

func _init(quest: Quest, initial_state: int, initial_goals_completed: Array[bool]) -> void:
	assert(quest)
	if not Utils.ensure(initial_goals_completed.size() == quest.get_decorated_goals().size()):
		initial_goals_completed.resize(quest.get_decorated_goals().size())
	assert(initial_state <= STATE_FINISHED)
	_quest = quest
	_state = initial_state
	_goals_completed = initial_goals_completed
	if _state == STATE_ACTIVE and initial_goals_completed.all(func(x: bool) -> bool: return x):
		_state = STATE_READY_TO_FINISH

	if Utils.is_running_in_single_scene_mode():
		push_warning('Running from a non-main scene. Cannot initialize quests.')
		return

	GlobalSaveGame.run_entered.connect(_on_run_entered)
	GlobalSaveGame.run_exited.connect(_on_run_exited)
	GlobalSaveGame.hub_entered.connect(_on_hub_entered)
	GlobalSaveGame.hub_exited.connect(_on_hub_exited)
	if Utils.get_active_run():
		_on_run_entered(Utils.get_active_run())
	elif Utils.get_active_hub():
		_on_hub_entered(Utils.get_active_hub())

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if not Utils.is_running_in_single_scene_mode():
			GlobalSaveGame.run_entered.disconnect(_on_run_entered)
			GlobalSaveGame.run_exited.disconnect(_on_run_exited)
			GlobalSaveGame.hub_entered.disconnect(_on_hub_entered)
			GlobalSaveGame.hub_exited.disconnect(_on_hub_exited)

func _on_run_entered(run: Run) -> void:
	if is_finished() and not _quest is Quest_Settler: return
	assert(not _listening_active)
	_quest.on_run_entered(self, run)
	_listening_active = true

func _on_run_exited(run: Run) -> void:
	if is_finished() and not _listening_active: return
	assert(_listening_active)
	_quest.on_run_exited(self, run)
	_listening_active = false

func _on_hub_entered(hub: Hub) -> void:
	if is_finished(): return
	assert(not _listening_active)
	_quest.on_hub_entered(self, hub)
	_listening_active = true

func _on_hub_exited(hub: Hub) -> void:
	if is_finished() and not _listening_active: return
	assert(_listening_active)
	_quest.on_hub_exited(self, hub)
	_listening_active = false

func get_quest() -> Quest:
	return _quest

func get_state() -> int:
	return _state

func is_active() -> bool:
	return _state >= STATE_ACTIVE and _state < STATE_FINISHED

func is_ready_to_finish() -> bool:
	return _state >= STATE_READY_TO_FINISH and _state < STATE_FINISHED

func is_finished() -> bool:
	return _state >= STATE_FINISHED

func is_goal_completed(index: int) -> bool:
	return _goals_completed[index]

func start() -> void:
	Utils.ensure(_state < STATE_ACTIVE)
	_state = STATE_ACTIVE
	changed.emit()
	GlobalSaveGame.quest_started.emit(self)

func update_progress(new_state: int) -> void:
	Utils.ensure(new_state >= STATE_ACTIVE and new_state <= STATE_FINISHED)
	_state = new_state
	changed.emit()

func finish(next_quest: Quest, auto_start: bool = true) -> void:
	Utils.ensure(is_ready_to_finish())
	_state = STATE_FINISHED
	GlobalSaveGame.quest_finished.emit(self)
	if next_quest:
		if GlobalSaveGame.get_quest_instance(next_quest):
			push_warning('Ignoring attempt to start duplicate quest: %s' % next_quest.quest_id)
		else:
			var next_instance := next_quest.instantiate(QuestInstance.STATE_ACTIVE if auto_start else QuestInstance.STATE_INACTIVE)
			if auto_start:
				GlobalSaveGame.quest_started.emit(next_instance)
			GlobalSaveGame.add_quest_instance(next_instance)
	changed.emit()

func get_current_goals() -> Array[GoalState]:
	Utils.ensure(_quest.get_decorated_goals().size() == _goals_completed.size())
	var result: Array[GoalState] = []
	var goals := _quest.get_decorated_goals()
	for i in goals.size():
		var goal := GoalState.new()
		goal.text = goals[i]
		goal.completed = _goals_completed[i]
		result.append(goal)
	return result

func set_goal_finished(i: int) -> void:
	Utils.ensure(is_active())
	if _goals_completed[i]:
		return  # Nothing to do. Don't emit signals.
	_goals_completed[i] = true
	var all_completed := true
	for completed in _goals_completed:
		if not completed:
			all_completed = false
			break
	if all_completed and _state < STATE_READY_TO_FINISH:
		_state = STATE_READY_TO_FINISH
	goal_finished.emit()
	changed.emit()

func set_goal_unfinished(i: int) -> void:
	Utils.ensure(_state != STATE_READY_TO_FINISH)
	_goals_completed[i] = false
	changed.emit()

class GoalState:
	var text: String
	var completed: bool
