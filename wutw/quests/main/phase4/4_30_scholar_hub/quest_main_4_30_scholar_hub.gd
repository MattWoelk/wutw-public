@tool
class_name Quest_Main430_ScholarHub
extends Quest

@export var begin_dialogue: Dialogue
@export var scholar_hub_shard_type: ShardType
@export var next_quest: Quest

func on_hub_entered(instance: QuestInstance, hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		_spawn_scholar(hub)  # Must be before the quest start to trigger the tutorial.
		instance.start()
		GlobalSaveGame.save_game()
	else:
		if GlobalSaveGame.get_past_run_by_shard_type(scholar_hub_shard_type):
			instance.set_goal_finished(0)
			# Not updating the main quest status yet to avoid showing the hub debate UI. The next quest will do it.
			instance.finish(next_quest, false)
			GlobalSaveGame.save_game()
		else:
			_spawn_scholar(hub)

func _spawn_scholar(hub: Hub) -> void:
	var clumsy_scholar_quest := load('res://quests/settler/quests/quest_settler_clumsy_scholar.tres') as Quest_Settler
	Utils.ensure(clumsy_scholar_quest != null)
	if GlobalSaveGame.get_quest_instance(clumsy_scholar_quest):
		# Can happen if reloaded after save.
		return
	var character := load('res://characters/generic/man/character_generic_man.tres') as Character
	var spec := character.hub_specs[16]
	var job := load('res://characters/jobs/job_scholar.tres')
	Utils.ensure(job in spec.allowed_jobs)
	var hub_character := spec.scene.instantiate() as HubCharacter
	hub_character.character = spec
	hub_character.job = job
	hub_character.origin = HubCharacter.Origin.REFUGEE
	hub_character.offered_quest = clumsy_scholar_quest
	Utils.ensure(hub.spawn_character(hub_character))
