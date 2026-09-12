@tool
class_name ShardType_MainQuest_ScholarsHub
extends ShardType

@export var required_job: Job

func score_requirement(_run_data: RunData, index: int) -> float:
	match index:
		0:
			var quest_started: bool
			for quest_instance in GlobalSaveGame.get_all_quest_instances():
				var settler_quest := quest_instance.get_quest() as Quest_Settler
				if settler_quest and required_job in settler_quest.restrict_to_jobs:
					if quest_instance.is_finished():
						return 1
					else:
						quest_started = true
			return 0 if quest_started else -1
		_: return -1

func describe_requirements() -> Array[String]:
	return [tr('Complete a settler quest for a %s.') % tr(required_job.job_name)]
