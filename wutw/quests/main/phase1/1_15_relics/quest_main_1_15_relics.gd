@tool
class_name Quest_Main115_Relics
extends Quest

const STATE_EVENT_STARTED := 110

@export var begin_dialogue: Dialogue
@export var talismans_event: Event
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	# Reset in case the game was saved then quit while the event was pending.
	if instance.get_state() == STATE_EVENT_STARTED:
		instance.update_progress(QuestInstance.STATE_ACTIVE)

	run.signals.relic_added.connect(_on_relic_added.bind(instance, run))
	run.signals.event_finished.connect(_on_event_finished.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.relic_added.disconnect(_on_relic_added.bind(instance, run))
	run.signals.event_finished.disconnect(_on_event_finished.bind(instance, run))

func _on_relic_added(_relic: Relic, instance: QuestInstance, run: Run) -> void:
	assert(instance)
	if instance.get_state() < STATE_EVENT_STARTED:
		instance.update_progress(STATE_EVENT_STARTED)
		run.queue_event(talismans_event)

func _on_event_finished(_event: Event, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if _event == talismans_event:
		talismans_event.mark_all_choices_seen()
		instance.set_goal_finished(0)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P115_GATHERED_RELICS)
		instance.finish(next_quest, false)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		instance.start()
		GlobalSaveGame.save_game()
